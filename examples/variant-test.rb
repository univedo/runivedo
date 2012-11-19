$: << File.dirname(__FILE__) + "/../lib"

require "runivedo"

connection = Runivedo::UConnection.new("ws://localhost:1600/6610CE92-9AF1-4D3F-ACDC-87B7A356C19E")

connection.send_obj "hallo"
connection.end_frame
puts "sent"
puts connection.receive
