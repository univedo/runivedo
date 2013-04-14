module Runivedo
  class Runivedo
    include Protocol

    attr_accessor :connection

    def initialize(url, args = {})
      @remote_objects = {}
      @stream = UStream.new
      @stream.onmessage = method(:onmessage)
      @stream.connect(url)
      @urologin = build_ro(0)
      @connection = @urologin.get_connection(args)
    end

    def close
      @stream.close
    end

    def build_ro(id)
      @remote_objects[id] = RemoteObject.new(stream: @stream, connection: self, id: id)
    end

    private

    def onmessage(message)
      ro_id = message.read
      raise "ro_id invalid" unless @remote_objects.has_key?(ro_id)
      @remote_objects[ro_id].send(:receive, message)
    end
  end
end
