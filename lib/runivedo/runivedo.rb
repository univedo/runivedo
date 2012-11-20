module Runivedo
  class Runivedo
    def initialize(url, args = {})
      @connection = UConnection.new(url)
    end

    def execute(query, &block)
      raise "no query" unless query
      result = UResult.new(@connection, query)
      result.run
      if block
        result.each(&block)
      end
      result
    end
  end
end
