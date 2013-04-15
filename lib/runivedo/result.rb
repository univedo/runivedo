module Runivedo
  class Result < RemoteObject
    include Enumerable

    def initialize(conn)
      @conn = conn
    end
  end
end
