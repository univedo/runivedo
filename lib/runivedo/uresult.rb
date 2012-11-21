module Runivedo
  class UResult
    include Enumerable

    attr_reader :affected_rows, :complete

    def initialize(connection, query)
      @connection = connection
      @query = query
      @affected_rows = nil
      @complete = false
      @run = false
    end

    def run
      @run = true
      @connection.send_obj(@query)
      status = @connection.receive
      # Do we have an error?
      case status
      when 10
      when 11
        # Receive affected rows info
        @affected_rows = @connection.receive.to_i
        @complete = true
      else
        @conn.handle_error(status)
      end
    end

    def next_row
      run unless @run
      return nil if @complete
      status = @connection.receive
      case status
      when 20
        cols_count = @connection.receive
        row = []
        cols_count.times do
          row << @connection.receive
        end
        row
      when 21
        @complete = true
        nil
      else
        @conn.handle_error(status)
      end
    end

    def each(&block)
      while row = next_row
        block.call(row)
      end
    end
  end
end
