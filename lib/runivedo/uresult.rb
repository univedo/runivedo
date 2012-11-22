module Runivedo
  class UResult
    include Enumerable
    include Protocol

    attr_reader :affected_rows, :complete

    def initialize(conn, query)
      @conn = conn
      @query = query
      @affected_rows = nil
      @complete = false
      @run = false
    end

    def run
      @run = true
      @conn.send_obj CODE_SQL
      @conn.send_obj(@query)
      @conn.send_obj(0) # TODO Binds
      @conn.end_frame
      status = @conn.receive
      # Do we have an error?
      case status
      when CODE_RESULT
      when CODE_MODIFICATION
        # Receive affected rows info
        @affected_rows = @conn.receive.to_i
        @complete = true
      else
        @conn.handle_error(status)
      end
    end

    def next_row
      run unless @run
      return nil if @complete
      status = @conn.receive
      case status
      when CODE_RESULT_MORE
        cols_count = @conn.receive
        row = []
        cols_count.times do
          row << @conn.receive
        end
        row
      when CODE_RESULT_CLOSED
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
