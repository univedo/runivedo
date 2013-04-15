$: << File.dirname(__FILE__) + "/../lib"

require "runivedo"

Thread.abort_on_exception=true

r = Runivedo::Connection.new("ws://mail.dast-online.de:9001/F8018F09-FB75-4D3D-8E11-44B2DC796130")
p = r.get_perspective("6e5a3a08-9bb0-4d92-ad04-7c6fed3874fa")
q = p.query
q.prepare("SELECT * FROM tables")
q.execute

