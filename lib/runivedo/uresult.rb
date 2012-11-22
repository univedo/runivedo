module Runivedo
  class UResult
    include Enumerable
    include Protocol

    attr_reader :affected_rows, :rows, :columns

    def initialize(conn, query, bindings = {})
      @conn = conn
      @query = query
      @bindings = bindings
      @affected_rows = nil
      @run = false
      @rows = nil
      @columns = nil
      @col_count = nil
    end

    def run
      @run = true
      @conn.send_obj CODE_SQL
      @conn.send_obj(@query)
      @conn.send_obj(@bindings.count)
      @bindings.each do |k, v|
        @conn.send_obj(k.to_s)
        @conn.send_obj(v)
      end
      @conn.end_frame
      @conn.receive_ok_or_error
      @affected_rows = @conn.receive
      @col_count = @conn.receive
      @columns = []
      @col_count.times { @columns << @conn.receive }
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
        row = []
        @col_count.times do
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
