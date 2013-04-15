module Runivedo
  class Connection
    include Protocol

    attr_accessor :stream

    def initialize(url, args = {})
      @remote_objects = {}
      @stream = Stream.new
      @stream.onmessage = method(:onmessage)
      @stream.connect(url)
      @urologin = RemoteObject.new(connection: self, id: 0)
      @connection_remote = @urologin.call_rom('getConnection', *args)
    end

    def get_perspective(name)
      @connection_remote.call_rom('getPerspective', name)
    end

    def close
      @stream.close
    end

    private

    def register_ro(id, obj)
      @remote_objects[id] = obj
    end

    def onmessage(message)
      ro_id = message.read
      raise "ro_id invalid" unless @remote_objects.has_key?(ro_id)
      @remote_objects[ro_id].send(:receive, message)
    end
  end
end
