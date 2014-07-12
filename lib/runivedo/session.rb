require "rfc-ws-client"
require "uuidtools"
require "cbor"

# Record Id Tag
# https://github.com/lucas-clemente/cbor-specs/blob/master/db_id.md
CBOR.register_tag(38) {|raw| raw}

module Runivedo
  @@ro_classes = {}

  def self.register_ro_class(name, klass)
    @@ro_classes[name] = klass
  end

  def self.ro_classes
    @@ro_classes
  end

  class Session
    attr_reader :error

    def initialize(url, args = {})
      @remote_objects = {}
      @ws = RfcWebSocket::WebSocket.new(url)
      Thread.new { handle_ws }
      @urologin = RemoteObject.new(self, 0)
      @remote_objects[0] = @urologin
      @session_remote = @urologin.call_rom('getSession', args)
    end

    def ping(v)
      @session_remote.ping(v)
    end

    def get_perspective(name, &block)
      @session_remote.get_perspective name, &block
    end

    def apply_uts(uts)
      @session_remote.apply_uts uts
    end

    def get_server_version
      @session_remote.get_server_version
    end

    def close
      @ws.close
      close_ros(Runivedo::ConnectionError.new("connection closed"))
    end

    def closed?
      @ws.closed?
    end

    private

    def handle_ws
      loop do
        msg, binary = @ws.receive
        raise Runivedo::ConnectionError.new("connection closed") if msg.nil?
        raise Runivedo::ConnectionError.new("received empty message") if msg.empty?

        # Read message to an array
        io = StringIO.new(msg)
        data = []
        session = self
        data << CBOR.load(io, 27 => method(:receive_ro)) while !io.eof?

        # Find remote object
        ro_id = data.shift
        ro = @remote_objects[ro_id]
        if ro.nil?
          # We cannot detect whether this is an unknown ro_id or a
          # previously closed one, so we just ignore it.
          next
        else
          ro.send :receive, data
        end
      end
    rescue => e
      @error = e
      close_ros(e)
    end

    def close_ros(reason)
      @remote_objects.each_value {|ro| ro.send :onclose, reason}
    end

    def send_message(data)
      @ws.send_message(data.map{|d| CBOR.dump(d)}.join, binary: true)
    end

    def receive_ro(raw)
      name, id = raw
      if klass = Runivedo.ro_classes[name]
        ro = klass.new(self, id)
      else
        ro = RemoteObject.new(self, id)
        ro.extend RemoteObject::MethodMissing
        ro
      end
      @remote_objects[id] = ro
      ro
    end

    # Sent from RemoteObject.close
    def delete_ro(id)
      @remote_objects.delete(id)
    end
  end
end
