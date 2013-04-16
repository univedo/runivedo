require 'thread'

module Runivedo
  class Future
    def initialize
      @mutex = Mutex.new
      @cond = ConditionVariable.new
      @completed = false
      @value = nil
    end

    def get
      @mutex.synchronize do
        @cond.wait(@mutex) unless @completed
      end
      @value
    end

    def complete(value)
      @mutex.synchronize do
        @completed = true
        @value = value
        @cond.broadcast
      end
    end
  end
end
