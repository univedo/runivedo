module Runivedo
  class RemoteObject
    include Protocol

    attr_accessor :id

    @@ro_classes = {}

    module MethodMissing
      def method_missing(name, *args)
        camelizedName = name.to_s.gsub(/_([a-z])/) { $1.capitalize}
        call_rom(camelizedName, *args)
      end
    end

    def initialize(connection: connection, id: id)
      @connection = connection
      @stream = @connection.stream
      @connection.send(:register_ro_instance, id, self)
      @id = id
      @call_id = 0
      @calls = {}
      @notifications = {}
    end
    
    def call_rom(name, *args)
      future = Future.new
      call_id = @call_id
      @calls[call_id] = future
      @call_id += 1
      @stream.send_message do |m|
        m << @id
        m << OPERATION_CALL_ROM
        m << call_id
        m << name
        args.each {|a| m << a}
      end
      message = future.get
      @calls.delete(call_id)
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

    def on(notification_name, &block)
      @notifications[notification_name.to_s] = block
    end

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

    def close
      @stream.send_message do |m|
        m << @id
        m << OPERATION_CLOSE
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
      opcode = message.read
      case opcode
      when OPERATION_ANSWER_CALL
        call_id = message.read
        raise "unknown call id" unless @calls.has_key?(call_id)
        @calls[call_id].complete(message)
      when OPERATION_NOTIFY
        name = message.read
        args = []
        args << message.read while message.has_data?
        notification(name, *args)
      else
        raise "unknown opcode #{opcode}"
      end
    end

    def onclose(reason)
      puts "close: #{reason}"
      reason = "connection closed" if reason.nil?
      @calls.each do |id, call|
        puts "failing call #{id}"
        call.fail(reason)
      end
    end
  end
end
