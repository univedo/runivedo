require "rfc-ws-client"

module Runivedo
  class UConnection
    include Protocol
    
    def initialize(url)
      @send_buffer = ""
      @receive_buffer = ""
      @ws = url ? RfcWebSocket::WebSocket.new(url) : nil
    end

    def send_obj(obj)
      @send_buffer += send_impl(obj)
    end

    def end_frame
      @ws.send_message(@send_buffer, binary: true)
      @send_buffer = ""
    end

    def receive()
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
        raise "unsupported type #{type}"
      end
    end

    def close
      @ws.close
    end

    def handle_error(status)
      raise "did not receive error code" unless status.is_a? Fixnum
      reason = receive
      case status
      when CODE_E_FATAL
        puts "Received fatal error: #{reason}".color(:red)
        puts "Exiting"
        exit CODE_E_FATAL
      when CODE_E_QUERY
        raise RunivedoSqlError.new(reason)
      else
        raise "unknown error"
      end
    end

    def receive_ok_or_error
      status = receive
      handle_error(status) if status != CODE_ACK
    end

    private

    def get_bytes(count, pack_opts)
      while @receive_buffer.size < count
        data, binary = @ws.receive
        raise "connection closed" if data.nil?
        raise "non-binary received" unless binary
        @receive_buffer << data
      end
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
        raise "sending not supported for class #{obj.class}"
      end
    end
  end
end
