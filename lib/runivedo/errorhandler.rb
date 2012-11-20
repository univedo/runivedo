class ErrorHandler
  def initialize(conn)
    @conn = conn
  end
  
  def error(status)
    raise "connection aborted" if status.nil?
    raise "protocol error"
  end
end