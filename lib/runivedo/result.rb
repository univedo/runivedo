module Runivedo
  class Result < RemoteObject
    include Enumerable
    RemoteObject.register_ro_class('UResult', self)

    def initialize(*args)
      super(*args)
      @rows = Queue.new
      @finished = false
      @numRows = -1
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
