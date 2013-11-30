module Runivedo
  class Connection
    include Protocol

    attr :stream

    def initialize(url, args = {})
      @remote_objects = {}
      @stream = Stream.new(self)
      @stream.onmessage = method(:onmessage)
      @stream.onclose = method(:onclose)
      @stream.connect(url)
      urologin = RemoteObject.new(connection: self, id: 0)
      @session_remote = urologin.call_rom('getSession', args)
    end

    def get_perspective(name, &block)
      @session_remote.call_rom('getPerspective', name, &block)
    end

    def set_perspective(name)
      @session_remote.call_rom('setPerspective', name)
    end

    def close
      @stream.close
    end

    def open?
      @session_remote.open?
    end

    private

    def register_ro_instance(id, obj)
      @remote_objects[id] = obj
      # ro_classes = Hash.new(0)
      # @remote_objects.map{|k, r| r.class}.each {|c| ro_classes[c] += 1}
      # puts ro_classes
    end

    def close_ro(id, reason)
      ro = @remote_objects[id]
      @remote_objects.delete(id)
      ro.send(:onclose, reason)
    end

    def onmessage(message)
      ro_id = message.read
      # This mitigates a race condition where notifications are sent to a dead remote object
      if @remote_objects.has_key?(ro_id)
        @remote_objects[ro_id].send(:receive, message)
      end
    end

    def onclose(reason)
      @remote_objects.each do |id, ro|
        close_ro(id, reason)
      end
    end
  end
end
