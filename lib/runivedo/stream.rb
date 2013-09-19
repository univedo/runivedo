require 'rfc-ws-client'
require 'date'
require 'uuidtools'

module Runivedo
  class Stream
    class Message
      attr_accessor :buffer

      include Runivedo::Variant

      def initialize(buffer = "", connection = nil)
        @buffer = buffer
        @connection = connection
        @data = []
        while @buffer.size > 0
          @data << read_impl
        end
      end

      def <<(obj)
        @buffer += send_impl(obj)
      end

      def has_data?
        @data.size > 0
      end

      def read
        raise 'message is empty' unless has_data?
        @data.shift
      end

      private

      def get_bytes(count, pack_opts)
        if @buffer.size < count
          raise "message finished"
        end
        @buffer.slice!(0, count).unpack(pack_opts)[0]
      end
    end

    attr_accessor :onmessage, :onclose
    
    def initialize(connection)
      @connection = connection
      @onmessage = lambda {}
      @onclose = lambda {}
    end

    def connect(url, &block)
      @ws = RfcWebSocket::WebSocket.new(url)
      Thread.new do
        loop do
          reason = nil
          begin
            msg, binary = @ws.receive
            raise "connection closed" if msg.nil?
            raise "received empty message" if msg.empty?
          rescue => e
            reason = e
          end
          if reason
            puts "closing stream: #{reason}"
            @onclose.call(reason)
            break
          end
          @onmessage.call(Message.new(msg, @connection))
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
