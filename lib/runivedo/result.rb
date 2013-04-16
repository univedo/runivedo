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
      when 'appendTuple'
        @rows << args.first
      when 'setErrorMessage'
        @rows << RunivedoSqlError.new("error executing query: #{args.first}")
      when 'setNTuplesAffected'
        @num_rows.complete(args.first)
      when 'setCompleted'
        @rows << nil
      else
        puts "received notification #{name}"
        p args
      end
    end
  end
end
