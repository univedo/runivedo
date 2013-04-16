module Runivedo
  class Result < RemoteObject
    include Enumerable
    RemoteObject.register_ro_class('result', self)

    def initialize(*args)
      super(*args)
      @rows = Queue.new
      @num_rows = Future.new
      @columns = Future.new
    end

    def num_affected_rows
      @num_rows.get
    end

    def columns
      @columns.get
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
      when 'setResultToField'
        p args
        @columns.complete(args.first.map { |f| f[1] })
      when 'appendTuple'
        @rows << args.first
      when 'setNTuplesAffected'
        @num_rows.complete(args.first)
      when 'setCompleted'
        @rows << nil
      when 'setErrorMessage'
        @rows << RunivedoSqlError.new("error executing query: #{args.first}")
      else
        puts "received notification #{name}"
      end
    end
  end
end
