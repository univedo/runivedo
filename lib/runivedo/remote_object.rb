require 'active_support/inflector'

module Runivedo
  class RemoteObject
    include Protocol

    def initialize(stream: stream, app: app, name: name, id: id)
      @stream = stream
      @id = id
      @call_id = 0
      @calls = {}
      @stream.send_message do |m|
        m << @id
        m << OPERATION_INSTANCIATE
        m << app
        m << name
      end
    end
    
    def method_missing(name, *args)
      event = Event.new
      call_id = @call_id
      @call_id += 1
      @calls[call_id] = {event: event}
      @stream.send_message do |m|
        m << @id
        m << OPERATION_CALL_ROM
        m << call_id
        m << name.to_s.camelize(:lower)
        args.each {|a| m << a}
      end
      event.wait
      message = @calls[call_id][:message]
      @calls.delete(call_id)
      status = message.read
      raise "got message status #{status}" unless status == 0
      message.read
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
      else
        raise "unknown opcode #{opcode}"
      end
    end
  end
end
