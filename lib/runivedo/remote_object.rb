require 'active_support/inflector'

module Runivedo
  class RemoteObject
    include Protocol

    def initialize(stream: stream, app: app, name: name, id: id)
      @stream = stream
      @id = id
      @call_id = 0
      @waiting_roms = {}
      @stream.send_message do |m|
        m << @id
        m << OPERATION_INSTANCIATE
        m << app
        m << name
      end
    end
    
    def method_missing(name, *args)
      puts "doing rom #{name.to_s.camelize(:lower)}"
      @stream.send_message do |m|
        m << (@id)
        m << (OPERATION_CALL_ROM)
        m << (@call_id)
        @call_id += 1
        m << (name.to_s.camelize(:lower))
        args.each {|a| m << (a)}
      end
    end

    private

    def receive(message)
      opcode = message.read
      case opcode
      when OPERATION_ANSWER_CALL
        raise unless message.read == 0
        p message.read
      else
        raise "unknown opcode #{opcode}"
      end
    end
  end
end
