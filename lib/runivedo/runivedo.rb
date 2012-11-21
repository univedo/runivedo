module Runivedo
  class Runivedo
    def initialize(args = {})
      raise "no url provided" unless args.has_key? :url
      raise "no user provided" unless args.has_key? :user
      raise "no password provided" unless args.has_key? :password
      raise "no uts provided" unless args.has_key? :uts
      @transaction = false
      @conn = UConnection.new(args[:url])
      @conn.send_obj 1
      @conn.send_obj args[:user]
      @conn.send_obj args[:password]
      @conn.send_obj args[:uts]
      status = @conn.receive
      error(status) unless status == 0
    end

    def close
      @conn.close
    end

    def begin
      @transaction = true
      @conn.send_obj 110
      status = @conn.receive
      error(status) unless status == 0
    end

    def commit
      raise "no transaction active" unless @transaction
      @transaction = false
      @conn.send_obj 111
      status = @conn.receive
      error(status) unless status == 0
    end

    def rollback
      raise "no transaction active" unless @transaction
      @transaction = false
      @conn.send_obj 112
      status = @conn.receive
      error(status) unless status == 0
    end

    def execute(query, &block)
      raise "no query" unless query
      result = UResult.new(@conn, query)
      result.run
      if block
        result.each(&block)
      end
      result
    end
  end
end
