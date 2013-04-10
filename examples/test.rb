$: << File.dirname(__FILE__) + "/../lib"

require "runivedo"

Thread.abort_on_exception=true

r = Runivedo::Runivedo.new("ws://mail.dast-online.de:9001/F8018F09-FB75-4D3D-8E11-44B2DC796130")
ro = r.build_ro('urologin', app: "23D84DC0-254A-4737-9D8B-3C789A050409")
ro.get_connection({"9744"=>"test", "9745"=>"secret"})
