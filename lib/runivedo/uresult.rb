module Runivedo
  class UResult
    include Enumerable
    include Protocol

    attr_reader :affected_rows, :rows

    def initialize(conn, query)
      @conn = conn
      @query = query
      @affected_rows = nil
      @run = false
      @rows = nil
    end

    def run
      @run = true
      @conn.send_obj CODE_SQL
      @conn.send_obj(@query)
      @conn.send_obj(0) # TODO Binds
      @conn.end_frame
      @conn.receive_ok_or_error
      @affected_rows = @conn.receive
      @rows = []
      while r = next_row
        @rows << r
      end
      @rows
    end


    def each(&block)
      run unless @run
      @rows.each(&block)
    end

    private

    def next_row
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
        nil
      else
        @conn.handle_error(status)
      end
    end
  end
end
