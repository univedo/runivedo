require 'rspec'
require 'runivedo'
require 'timeout'

class MockStream
  attr_accessor :callback, :sent_data

  def send_message(&block)
    @sent_data ||= []
    yield @sent_data
    @callback.call if @callback
  end
end

class MockMessage
  def initialize(*data)
    @data = data
  end

  def read
    @data.shift
  end

  def has_data?
    @data.count > 0
  end
end

RSpec.configure do |c|
  c.around(:each) do |example|
    Timeout::timeout(1) {
      example.run
    }
  end
end
