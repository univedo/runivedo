require 'active_support/inflector'

module Runivedo
  class RemoteObject
    include Protocol

    attr_accessor :id

    def initialize(connection: connection, id: id)
      @stream = connection.stream
      @connection = connection
      @connection.register_ro_instance(id, self)
      @id = id
      @call_id = 0
      @calls = {}
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
      when 1
        thread_id, name = message.read
        klass = @@ro_classes[name] || RemoteObject
        klass.new(connection: @connection, id: thread_id)
      else
        raise "got message status #{status}" unless status == 0
      end
    end

    module MethodMissing
      def method_missing(name, *args)
        call_rom(name.to_s.camelize(:lower), *args)
      end
    end

    @@ro_classes = {}

    def self.register_ro_class(name, klass)
      @@ro_classes[name] = klass
    end

    def self.unregister_ro_class(name)
      @@ro_classes.delete(name)
    end

    private

    def notification(name, *args)
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
  end
end
