module Runivedo
  class UResult
    include Enumerable

    attr_reader :affected_rows, :complete

    def initialize(connection, query)
      @connection = connection
      @query = query
      @affected_rows = nil
      @complete = false
    end

    def run
      @connection.send_obj(@query)
      status = @connection.receive
      raise "protocol error" unless status.is_a?(Fixnum)
      # Do we have an error?
      case status
      when 0
      when 1
        # Receive affected rows info
        @affected_rows = @connection.receive.to_i
        @complete = true
      else
        # Error
        error_msg = @connection.receive
        @complete = true
        raise error_msg.to_s
      end
    end

    def next_row
      return nil if @complete
      status = @connection.receive
      case status
      when 0
        cols_count = @connection.receive
        row = []
        cols_count.times do
          row << @connection.receive
        end
        row
      when 1
        @complete = true
        nil
      else
        raise "unexpected status #{status} while receiving rows"
      end
    end

    def each(&block)
      while row = next_row
        block.call(row)
      end
    end
  end
end