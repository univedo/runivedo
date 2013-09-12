$: << File.dirname(__FILE__) + "/../lib"

require "runivedo"

Thread.abort_on_exception=true

runivedo = Runivedo::Connection.new("ws://192.168.3.22:9001/f8018f09-fb75-4d3d-8e11-44b2dc796130", 0x2610 => "marvin")
query = runivedo.get_perspective("6e5a3a08-9bb0-4d92-ad04-7c6fed3874fa").query

i = 0
loop do
  puts i
  i += 1
  puts query.prepare('SELECT * FROM fields').execute.count
end
