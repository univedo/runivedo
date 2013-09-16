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
      def method_missing(name, *args)
        camelizedName = name.to_s.gsub(/_([a-z])/) { $1.capitalize}
        call_rom(camelizedName, *args)
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
        raise message unless success
        status = message.read
        case status
        when 0
          message.read
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
      @mutex.synchronize do
        @connection.stream.send_message do |m|
          m << @id
          m << OPERATION_CLOSE
        end
        onclose("closed")
      end
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
