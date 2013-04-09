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
        @cond.wait(@mutex) while !@set
      end
    end

    def signal
      @mutex.synchronize do
        @set = true
        @cond.signal
      end
    end
  end
end
