require 'thread'

module Runivedo
  class Future
    def initialize
      @mutex = Mutex.new
      @cond = ConditionVariable.new
      @success = nil
      @value = nil
    end

    def get
      @mutex.synchronize do
        @cond.wait(@mutex) while @success.nil?
      end
      if @success
        @value
      else
        raise @value
      end
    end

    def fail(exception)
      @mutex.synchronize do
        @success = false
        @value = exception
        @cond.broadcast
      end
    end

    def complete(value)
      @mutex.synchronize do
        @success = true
        @value = value
        @cond.broadcast
      end
    end
  end
end
