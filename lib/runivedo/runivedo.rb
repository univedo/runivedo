require "runivedo/uconnection"

module Runivedo
  class Runivedo
    def initialize(host, args = {})
      @messages = Queue.new
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
            @messages << msg
          end
        end
      end
    end


  end
end
