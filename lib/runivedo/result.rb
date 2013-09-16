module Runivedo
  class Result < RemoteObject
    include Enumerable
    RemoteObject.register_ro_class('result', self)

    def initialize(*args)
      super(*args)
      @rows = Queue.new
      @num_rows = Future.new
      @columns = Future.new

      self.on('setResultToField') { |*args| @columns.complete(args.first.map { |f| f[1] }) }
      self.on('appendTuple') { |t| @rows << t }
      self.on('setNTuplesAffected') { |n| @num_rows.complete(n) }
      self.on('setCompleted') { @rows << nil }
      self.on('setErrorMessage') { |msg| @rows << RunivedoSqlError.new("error executing query: #{msg}") }
      self.on('setNColumns') { |*| }
      self.on('tuplesAffected') { |*| }
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
  end
end
