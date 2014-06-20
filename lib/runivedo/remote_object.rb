module Runivedo
  class RemoteObject
    OPERATION_CALL_ROM = 1
    OPERATION_ANSWER_CALL = 2
    OPERATION_NOTIFY = 3
    OPERATION_DELETE = 4

    module MethodMissing
      def method_missing(name, *args, &block)
        camelizedName = name.to_s.gsub(/_([a-z])/) { $1.capitalize }
        if camelizedName.start_with?('set')
          send_notification(camelizedName, *args)
        else
          call_rom(camelizedName, *args, &block)
        end
      end
    end

    def initialize(session, id)
      @session = session
      @open = true
      @id = id
      @call_id = 0
      @calls = {}
      @notifications = {}
      @mutex = Mutex.new
    end

    def send_notification(name, *args)
      @mutex.synchronize do
        check_open
        @session.send :send_message, [@id, OPERATION_NOTIFY, name.to_s, args]
      end
    end

    def call_rom(name, *args)
      call_result = nil
      @mutex.synchronize do
        check_open
        call_result = Future.new
        @calls[@call_id] = call_result
        @session.send :send_message, [@id, OPERATION_CALL_ROM, @call_id, name, args]
        @call_id += 1
      end
      result = call_result.get
      if result.is_a?(RemoteObject) && block_given?
        begin
          yield result
        ensure
          result.close
        end
      else
        result
      end
    end

    def on(notification_name, &block)
      @notifications[notification_name.to_s] = block
    end

    def closed?
      !@open
    end

    def close
      @session.send :delete_ro, @id
      onclose(Runivedo::ConnectionError.new("remote object closed"))
      @session.send :send_message, [@id, OPERATION_DELETE]
    end

    private

    def check_open
      raise Runivedo::ConnectionError.new("remote object closed") unless @open
    end

    def onclose(reason)
      @mutex.synchronize do
        return unless @open
        @open = false
        @calls.each_value do |c|
          c.fail(reason)
        end
      end
    end

    def receive(data)
      opcode = data.shift
      case opcode
      when OPERATION_ANSWER_CALL
        call_id = data.shift
        future = @calls[call_id]
        raise Runivedo::ConnectionError.new("unknown call id #{call_id}") unless future
        @calls.delete(call_id)
        status = data.shift
        case status
        when 0
          result = data.shift
          future.complete(result)
        when 2
          error = data.shift
          future.fail Runivedo::SqlError.new(error)
        else
          raise Runivedo::ConnectionError.new("unknown status #{status}")
        end
      when OPERATION_NOTIFY
        name = data.shift
        args = data.shift
        if block = @notifications[name]
          block.call(*args)
        else
          raise Runivedo::ConnectionError.new("unknown notification #{name}")
        end
      else
        raise Runivedo::ConnectionError.new("received invalid opcode #{opcode}")
      end
    end
  end
end
