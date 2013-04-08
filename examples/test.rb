$: << File.dirname(__FILE__) + "/../lib"

require "runivedo"

# stream = Runivedo::Runivedo.new(url: "ws://echo.websocket.org")
stream = Runivedo::Runivedo.new(url: "ws://192.168.100.105:9001/F8018F09-FB75-4D3D-8E11-44B2DC796130")
