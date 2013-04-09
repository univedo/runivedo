require 'rspec'
require 'runivedo'

include Runivedo::Protocol

class MockStream
  attr_reader :sent_data, :recv_data

  def initialize
    @sent_data = []
  end

  def send_message(&block)
    yield @sent_data
  end
end

RSpec.configure do |config|
end
