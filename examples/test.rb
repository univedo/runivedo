$: << File.dirname(__FILE__) + "/../lib"

require "runivedo"

Thread.abort_on_exception=true

runivedo = Runivedo::Connection.new("ws://10.0.0.42:9001/f8018f09-fb75-4d3d-8e11-44b2dc796130")
query = runivedo.get_perspective("6e5a3a08-9bb0-4d92-ad04-7c6fed3874fa").query
loop do
  query.prepare('SELECT * FROM tables').execute.to_a
end
