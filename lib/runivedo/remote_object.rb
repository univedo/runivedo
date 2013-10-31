module Runivedo
  class RemoteObject
    include Protocol

    # Class stuff

    @@ro_classes = {}

    def self.register_ro_class(name, klass)
      @@ro_classes[name] = klass
    end

    def self.unregister_ro_class(name)
      @@ro_classes.delete(name)
    end

    def self.create_ro(name: name, connection: connection, thread_id: thread_id)
      if @@ro_classes.has_key?(name)
        @@ro_classes[name].new(connection: connection, id: thread_id)
      else
        ro = RemoteObject.new(connection: connection, id: thread_id)
        ro.extend(MethodMissing)
        ro
      end
    end

    # Instance stuff

    module MethodMissing
      def method_missing(name, *args, &block)
        camelizedName = name.to_s.gsub(/_([a-z])/) { $1.capitalize}
        call_rom(camelizedName, *args, &block)
      end
    end

    attr_accessor :id

    def initialize(connection: connection, id: id)
      @connection = connection
      @connection.send(:register_ro_instance, id, self)
      @open = true
      @id = id
      @call_id = 0
      @calls = {}
      @notifications = {}
      @mutex = Mutex.new
      @cond = ConditionVariable.new
    end
    
    def call_rom(name, *args)
      @mutex.synchronize do
        raise "remote object closed" unless @open
        call_id = @call_id
        @call_id += 1
        @calls[call_id] = {success: nil}
        @connection.stream.send_message do |m|
          m << @id
          m << OPERATION_CALL_ROM
          m << call_id
          m << name
          args.each {|a| m << a}
        end
        @cond.wait(@mutex) while @calls[call_id][:success].nil?
        success, message = @calls[call_id].values_at(:success, :value)
        @calls.delete(call_id)
        unless success
          message.set_backtrace caller
          raise message
        end
        status = message.read
        case status
        when 0
          # If result is a remote object and we have a block pass it as parameter and close again
          result = message.read
          if result.is_a?(RemoteObject) && block_given?
            begin
              yield result
            ensure
              result.close
              return nil
            end
          end
          result
        when 2
          raise RunivedoSqlError.new(message.read)
        else
          raise "got message status #{status}" unless status == 0
        end
      end
    end

    def on(notification_name, &block)
      @notifications[notification_name.to_s] = block
    end

    def close
      @connection.stream.send_message do |m|
        m << @id
        m << OPERATION_DELETE
      end
      @connection.send(:close_ro, @id, "closed")
    end

    private

    def notification(name, *args)
      if @notifications.has_key?(name)
        @notifications[name].call(*args)
      else
        puts "unknown notification #{name}"
      end
    end

    def receive(message)
      @mutex.synchronize do
        return if @closed
        opcode = message.read
        case opcode
        when OPERATION_ANSWER_CALL
          call_id = message.read
          raise "unknown call id" unless @calls.has_key?(call_id)
          @calls[call_id][:success] = true
          @calls[call_id][:value] = message
          @cond.broadcast
        when OPERATION_NOTIFY
          name = message.read
          args = []
          args << message.read while message.has_data?
          notification(name, *args)
        else
          raise "unknown opcode #{opcode}"
        end
      end
    end

    def onclose(reason)
      @mutex.synchronize do
        @open = false
        @calls.each do |id, call|
          call[:success] = false
          call[:value] = reason
        end
        @cond.broadcast
      end
    end
  end
end
