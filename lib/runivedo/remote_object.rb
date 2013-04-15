require 'active_support/inflector'

module Runivedo
  class RemoteObject
    include Protocol

    def initialize(stream: stream, connection: connection, id: id)
      @stream = stream
      @connection = connection
      @id = id
      @call_id = 0
      @calls = {}
    end
    
    def method_missing(name, *args)
      call_rom(name.to_s.camelize(:lower), *args)
    end

    def call_rom(name, *args)
      event = Event.new
      call_id = @call_id
      @call_id += 1
      @calls[call_id] = {event: event}
      @stream.send_message do |m|
        m << @id
        m << OPERATION_CALL_ROM
        m << call_id
        m << name
        args.each {|a| m << a}
      end
      event.wait
      message = @calls[call_id][:message]
      @calls.delete(call_id)
      status = message.read
      case status
      when 0
        message.read
      when 1
        @connection.build_ro(message.read)
      else
        raise "got message status #{status}" unless status == 0
      end
    end

    def notification(name, *args)
    end

    private

    def receive(message)
      opcode = message.read
      case opcode
      when OPERATION_ANSWER_CALL
        call_id = message.read
        raise "unknown call id" unless @calls.has_key?(call_id)
        @calls[call_id][:message] = message
        @calls[call_id][:event].signal
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
