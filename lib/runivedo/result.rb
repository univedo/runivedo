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
      self.on('appendTuple') { |*args| @rows << args.first }
      self.on('setNTuplesAffected') { |*args| @num_rows.complete(args.first) }
      self.on('setCompleted') { |*args| @rows << nil }
      self.on('setErrorMessage') { |*args| @rows << RunivedoSqlError.new("error executing query: #{args.first}") }
      self.on('setNColumns') { |*args| }
      self.on('tuplesAffected') { |*args| }
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
