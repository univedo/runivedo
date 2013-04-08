module Runivedo
  class RemoteObject
    include Protocol

    def initialize(stream: stream, app: app, name: name, id: id)
      @stream = stream
      @id = id
      @call_id = 0
      @waiting_roms = {}
      @stream.send_obj(OPERATION_INSTANCIATE)
      @stream.send_obj(@id)
      @stream.send_obj(app)
      @stream.send_obj(name)
      @stream.end_frame
    end

    def receive_return
      raise unless @stream.receive == 0
      p @stream.receive
    end
    
    def method_missing(name, *args)
      puts "doing rom #{name.to_s.camelize(:lower)}"
      @stream.send_obj(OPERATION_CALL_ROM)
      @stream.send_obj(@id)
      @stream.send_obj(@call_id)
      @stream.send_obj(name.to_s.camelize(:lower))
      args.each {|a| @stream.send_obj(a)}
      @stream.end_frame
    end
  end
end
