require 'rfc-ws-client'

module Runivedo
  class Stream
    class Message
      attr_accessor :buffer

      def initialize(buffer = "")
        @buffer = buffer
      end

      def <<(obj)
        @buffer += send_impl(obj)
      end

      def has_data?
        @buffer.size > 0
      end

      def read
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
        when 60
          count = get_bytes(4, "L")
          count.times.map { read }
        when 61
          count = get_bytes(4, "L")
          Hash[count.times.map { [read, read] }]
        when 45
          [get_bytes(4, "L"), read]
        else
          raise "unsupported type #{type}"
        end
      end

      private

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
        when Array
          [60, obj.count].pack("CL") + obj.map{|e| send_impl(e)}.join
        when Hash
          [61, obj.count].pack("CL") + obj.map{|k, v| send_impl(k) + send_impl(v)}.join
        else
          raise "sending not supported for class #{obj.class}"
        end
      end

      def get_bytes(count, pack_opts)
        if @buffer.size < count
          raise "message finished"
        end
        @buffer.slice!(0, count).unpack(pack_opts)[0]
      end
    end

    attr_accessor :onmessage
    
    def initialize
      @onmessage = lambda {}
    end

    def connect(url, &block)
      @ws = RfcWebSocket::WebSocket.new(url)
      Thread.new do
        loop do
          msg, binary = @ws.receive
          @onmessage.call(Message.new(msg))
        end
      end
    end

    def send_message(&block)
      m = Message.new
      block.call(m)
      @ws.send_message(m.buffer, binary: true)
    end

    def close
      @ws.close
    end
  end
end
