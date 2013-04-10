require 'thread'

module Runivedo
  class Event
    def initialize
      @mutex = Mutex.new
      @cond = ConditionVariable.new
      @set = false
    end

    def wait
      @mutex.synchronize do
        @cond.wait(@mutex) unless @set
      end
    end

    def signal
      @mutex.synchronize do
        @set = true
        @cond.broadcast
      end
    end
  end
end
