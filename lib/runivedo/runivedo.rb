module Runivedo
  class Runivedo
    include Protocol

    def initialize(args = {})
      raise "no url provided" unless args.has_key? :url
      @remote_objects = {}
      @stream = UStream.new
      @stream.onclose = method(:onclose)
      @stream.onmessage = method(:onmessage)
      @stream.connect(args[:url]) do
        puts "connected"
        @urologin = build_ro(UROLOGIN_NAME, app: DOORKEEPER_UUID)
        @urologin.get_required_credentials
      end
    end

    def close
      @stream.close
    end

    private

    def build_ro(name, app: app)
      @next_id ||= 1
      ro = RemoteObject.new(stream: @stream, name: name, app: app, id: @next_id)
      @remote_objects[@next_id] = ro
      @next_id += 2
      ro
    end

    def onclose
      puts "closed"
      exit
    end

    def onmessage
      ro_id = @stream.receive
      raise "ro_id invalid" unless @remote_objects.has_key?(ro_id)
      @remote_objects[ro_id].receive
    end
  end
end
