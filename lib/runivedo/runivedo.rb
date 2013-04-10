module Runivedo
  class Runivedo
    include Protocol

    def initialize(url, args = {})
      @remote_objects = {}
      @stream = UStream.new
      @stream.onclose = method(:onclose)
      @stream.onmessage = method(:onmessage)
      opened = Event.new
      @stream.connect(url) do
        puts "connected"
        opened.signal
      end
      opened.wait
      if args.has_key?(:auth)
        @urologin = build_ro(UROLOGIN_NAME, app: DOORKEEPER_UUID)
        p @urologin.get_required_credentials
      end
    end

    def close
      @stream.close
    end

    def build_ro(name, app: app)
      @next_id ||= 1
      ro = RemoteObject.new(stream: @stream, name: name, app: app, id: @next_id)
      @remote_objects[@next_id] = ro
      @next_id += 2
      ro
    end

    private

    def onclose
      puts "closed"
      exit
    end

    def onmessage(message)
      ro_id = message.read
      raise "ro_id invalid" unless @remote_objects.has_key?(ro_id)
      @remote_objects[ro_id].send(:receive, message)
    end
  end
end
