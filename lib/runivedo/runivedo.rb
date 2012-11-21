module Runivedo
  class Runivedo
    def initialize(args = {})
      raise "no url provided" unless args.has_key? :url
      raise "no user provided" unless args.has_key? :user
      raise "no password provided" unless args.has_key? :password
      raise "no uts provided" unless args.has_key? :uts
      @transaction = false
      @conn = UConnection.new(args[:url])
      @err_handler = ErrorHandler.new(@conn)
      @conn.send_obj 1
      @conn.send_obj args[:user]
      @conn.send_obj args[:password]
      @conn.send_obj args[:uts]
      @conn.receive_ok_or_error
    end

    def close
      @conn.close
    end

    def begin
      @transaction = true
      @conn.send_obj 110
      @conn.receive_ok_or_error
    end

    def commit
      raise "no transaction active" unless @transaction
      @transaction = false
      @conn.send_obj 111
      @conn.receive_ok_or_error
    end

    def rollback
      raise "no transaction active" unless @transaction
      @transaction = false
      @conn.send_obj 112
      @conn.receive_ok_or_error
    end

    def execute(query, &block)
      raise "no query" unless query
      result = UResult.new(@conn, @err_handler, query)
      result.run
      if block
        result.each(&block)
      end
      result
    end
  end
end
