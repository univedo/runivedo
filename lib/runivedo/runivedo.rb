module Runivedo
  class Runivedo
    include Protocol

    def initialize(args = {})
      raise "no url provided" unless args.has_key? :url
      @remote_objects = {}
      @stream = UStream.new
      @stream.on_close do
        puts "close"
        exit
      end
      @stream.on_message do
        operation = @stream.receive
        case operation
        when OPERATION_ANSWER_CALL
          @remote_objects[@stream.receive].receive_return
        end
      end
      @stream.connect(args[:url]) do
        puts "open"
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
  end
end
