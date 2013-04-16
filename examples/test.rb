$: << File.dirname(__FILE__) + "/../lib"

require "runivedo"

Thread.abort_on_exception=true

runivedo = Runivedo::Connection.new("ws://84.164.176.88:9001/f8018f09-fb75-4d3d-8e11-44b2dc796130")
query = runivedo.get_perspective("6e5a3a08-9bb0-4d92-ad04-7c6fed3874fa").query
query.prepare("SELECT * FROM tables")
query.execute.each do |row|
  p row
end
