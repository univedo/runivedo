module Runivedo
  class Result < RemoteObject
    include Enumerable
    RemoteObject.register_ro_class('UResult', self)

    def initialize(*args)
      super(*args)
      @rows = Queue.new
      @num_rows = Future.new
    end

    def number_of_rows
      @num_rows.get
    end

    def each(&block)
      while row = @rows.pop
        raise row if row.is_a? Exception
        block.call(row)
      end
    end

    private

    def notification(name, *args)
      case name
      when 'nextRow'
        @rows << args.first
      when 'error'
        @rows << RunivedoSqlError.new("error executing query")
      when 'finished'
        num_rows, dummy = *args
        @num_rows.complete(num_rows)
        @rows << nil
      end
    end
  end
end
