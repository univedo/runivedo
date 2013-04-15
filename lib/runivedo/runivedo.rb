module Runivedo
  class Runivedo
    include Protocol

    attr_accessor :connection

    def initialize(url, args = {})
      @remote_objects = {}
      @stream = UStream.new
      @stream.onmessage = method(:onmessage)
      @stream.connect(url)
      @urologin = RemoteObject.new(stream: @stream, connection: self, id: 0)
      @connection = @urologin.get_connection(args)
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
