require 'rspec'
require 'runivedo'

include Runivedo::Protocol

class MockConnection
  attr_reader :sent_data, :recv_data

  def initialize
    @sent_data = []
    @recv_data = []
    @i = 0
  end

  def send_obj(msg)
    @sent_data << msg
  end

  def receive
    @i += 1
    @recv_data[@i-1]
  end

  def end_frame
  end
end

RSpec.configure do |config|
end
