module Runivedo
  class Runivedo
    def initialize(url, args = {})
      @connection = UConnection.new(url)
    end

    def execute(query)
      raise "no query" unless query
    end
  end
end
