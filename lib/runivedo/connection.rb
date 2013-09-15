module Runivedo
  class Connection
    include Protocol

    attr_accessor :stream

    def initialize(url, args = {})
      @remote_objects = {}
      @stream = Stream.new(self)
      @stream.onmessage = method(:onmessage)
      @stream.onclose = method(:onclose)
      @stream.connect(url)
      urologin = RemoteObject.new(connection: self, id: 0)
      @session_remote = urologin.call_rom('getSession', args)
    end

    def get_perspective(name)
      @session_remote.call_rom('getPerspective', name)
    end

    def set_perspective(name)
      @session_remote.call_rom('setPerspective', name)
    end

    def close
      @stream.close
    end

    private

    def register_ro_instance(id, obj)
      @remote_objects[id] = obj
    end

    def onmessage(message)
      ro_id = message.read
      raise "ro_id invalid" unless @remote_objects.has_key?(ro_id)
      @remote_objects[ro_id].send(:receive, message)
    end

    def onclose(reason)
      @remote_objects.each do |id, ro|
        puts "closing ro #{id}"
        ro.send(:onclose, reason)
      end
    end
  end
end
