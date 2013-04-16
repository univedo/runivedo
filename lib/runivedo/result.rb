module Runivedo
  class Result < RemoteObject
    include Enumerable
    RemoteObject.register_ro_class('UResult', self)

    def initialize(*args)
      super(*args)
      @rows = Queue.new
      @finished = false
      @numRows = Future.new
    end

    def number_of_rows
      @numRows.get
    end

    private

    def notification(name, *args)
      case name
      when 'nextRow'

      when 'error'

      when 'finished'

      end
    end
  end
end
