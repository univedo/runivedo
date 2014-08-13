module Runivedo
  class Statement < RemoteObject
    Runivedo.register_ro_class('com.univedo.statement', self)
    include Runivedo::RemoteObject::MethodMissing

    def initialize(*args)
      super(*args)
      @column_names = Future.new
      @column_types = Future.new
      on('setColumnNames') {|cols| @column_names.complete(cols)}
      on('setColumnTypes') {|types| @column_types.complete(types)}
    end

    def column_names
      @column_names.get
    end

    def column_types
      @column_types.get
    end

    def execute(binds = {}, &block)
      call_rom("execute", binds, &block)
    end
  end

  class Result < RemoteObject
    Runivedo.register_ro_class('com.univedo.result', self)
    include Enumerable

    def initialize(*args)
      super(*args)
      @rows = Queue.new
      @record_id = Future.new
      @n_affected = Future.new

      self.on('setError') do |msg|
        err = Runivedo::SqlError.new(msg)
        @rows << err
        @record_id.fail(err)
        @n_affected.fail(err)
      end

      # SELECT
      self.on('setComplete') { complete_futures }
      self.on('setTuple') { |t| @rows << t }

      # UPDATE, DELETE, LINK
      self.on('setNAffectedRecords') { |n| complete_futures(n_affected: n) }

      # INSERT
      self.on('setId') { |id| complete_futures(record_id: id) }
    end

    def num_affected_rows
      @n_affected.get
    end

    def last_inserted_id
      @record_id.get
    end

    def each(&block)
      while row = @rows.pop
        raise row if row.is_a? Exception
        block.call(row)
      end
    end

    private

    def complete_futures(values = {})
      @n_affected.complete(values[:n_affected]) unless @n_affected.is_complete?
      @record_id.complete(values[:record_id]) unless @record_id.is_complete?
      @rows << nil
    end
  end
end
