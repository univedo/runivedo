require "em-ws-client"

module Runivedo
  class UConnection
    def initialize(host, args = {})
      @messages = Queue.new
      @send_buffer = ""
      @receive_buffer = nil
      return unless host
      m = Mutex.new
      c = ConditionVariable.new
      Thread.new do
        EM.run do
          ws = EM::WebSocketClient.new(host)

          ws.onopen do
            puts "connected"
            m.synchronize { c.signal }
          end

          ws.onclose do |code, explain|
            puts "closed: #{code}, #{explain}"
          end

          ws.onerror do |code, message|
            puts "error: #{code}, #{message}"
          end

          ws.onmessage do |msg, binary|
            throw "non-binary received" unless binary
            @messages << msg
          end
        end
      end
      m.synchronize { c.wait(m) }
    end

    def send_obj(obj)
      send_buffer += send_impl(obj)
    end

    def receive()
      @receive_buffer = @messages.pop unless @receive_buffer
      type = get_bytes(1, "C")
      case type
      when 0
        nil
      when 1
        get_bytes(1, "C") == 1 ? true : false
      when 10
        get_bytes(1, "c")
      when 11
        get_bytes(2, "s")
      when 12
        get_bytes(4, "l")
      when 13
        get_bytes(8, "q")
      when 15
        get_bytes(1, "C")
      when 16
        get_bytes(2, "S")
      when 17
        get_bytes(4, "L")
      when 18
        get_bytes(8, "Q")
      when 20
        get_bytes(4, "f")
      when 21
        get_bytes(8, "d")
      when 30
        count = get_bytes(4, "L")
        get_bytes(count, "a*")
      when 31
        count = get_bytes(4, "L")
        chars = []
        count.times { chars << get_bytes(2, "S") }
        chars.pack("U*")
      else
        throw "unsupported type #{type}"
      end
    end

    private

    def get_bytes(count, pack_opts)
      @receive_buffer.slice!(0, count).unpack(pack_opts)[0]
    end

    def send_impl(obj)
      case obj
      when nil
        "\x00"
      when TrueClass, FalseClass
        [1, obj ? 1 : 0].pack("CC")
      when Fixnum
        [13, obj].pack("Cq")
      when Float
        [21, obj].pack("Cd")
      when String
        [30, obj.bytesize, obj].pack("CLa*")
      else
        throw "sending not supported for class #{obj.class}"
      end
    end
  end
end
