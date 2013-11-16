module Runivedo
  class Result < RemoteObject
    include Enumerable
    RemoteObject.register_ro_class('result', self)

    def initialize(*args)
      super(*args)
      @rows = Queue.new
      @record = Future.new
      @affected = Future.new

      self.on('setError') do |msg|
        err = RunivedoSqlError.new(msg)
        @rows << err
        @record.fail(err)
        @affected.fail(err)
      end

      # SELECT
      self.on('setComplete') { complete_futures }
      self.on('appendTuple') { |t| @rows << t }

      # UPDATE, DELETE, LINK
      self.on('setAffectedRecords') { |ids| @affected.complete(ids); complete_futures }

      # INSERT
      self.on('setRecord') { |id| @record.complete(id); complete_futures }
    end

    def affected_rows
      @affected.get
    end

    def num_affected_rows
      @affected.get ? @affected.get.count : nil
    end

    def last_inserted_id
      @record.get
    end

    def each(&block)
      while row = @rows.pop
        raise row if row.is_a? Exception
        block.call(row)
      end
    end

    private

    def complete_futures
      [@affected, @record].each { |f| f.complete(nil) unless f.is_complete? }
      @rows << nil
    end
  end
end
