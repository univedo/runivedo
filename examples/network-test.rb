$: << File.dirname(__FILE__) + "/../lib"

require "runivedo"

stream = Runivedo::UStream.new("ws://192.168.100.105:9001/F8018F09-FB75-4D3D-8E11-44B2DC796130")

stream.send_obj "hallo"
stream.end_frame
puts stream.receive
stream.close
