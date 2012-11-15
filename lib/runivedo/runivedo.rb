require "runivedo/uconnection"

module Runivedo
  class Runivedo
    def initialize(url, args = {})
      @connection = UConnection.new(url)
      @query = nil
    end

    def prepare(query)
      @query = query
    end

    def execute
      throw "no query" unless @query
      @connection.send(query)
      @query = nil
      # TODO Receive results
    end
  end
end
