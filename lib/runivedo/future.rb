require 'thread'

module Runivedo
  class Future
    def initialize
      @mutex = Mutex.new
      @cond = ConditionVariable.new
      @completed = nil
      @value = nil
    end

    def get
      @mutex.synchronize do
        @cond.wait(@mutex) unless @completed
      end
      if @completed == :success
        @value
      else
        raise @value
      end
    end

    def fail(exception)
      @mutex.synchronize do
        @completed = :exception
        @value = exception
        @cond.broadcast
      end
    end

    def complete(value)
      @mutex.synchronize do
        @completed = :success
        @value = value
        @cond.broadcast
      end
    end
  end
end
