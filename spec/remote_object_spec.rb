require "spec_helper"

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

describe Runivedo::RemoteObject do
  let(:stream) { MockStream.new }
  let(:connection) { c = double(:connection); c.stub(:register_ro); c.stub(:stream).and_return(stream); c }
  let(:ro) { Runivedo::RemoteObject.new(connection: connection, id: 2) }

  it 'does rom calls' do
    ro
    stream.callback = lambda {ro.send(:receive, MockMessage.new(2, 0, 0, 42))}
    ro.call_rom('foo').should == 42
    stream.sent_data.should == [2, 1, 0, 'foo']
    # Second call
    stream.sent_data.clear
    stream.callback = lambda {ro.send(:receive, MockMessage.new(2, 1, 0, 42))}
    ro.call_rom('fooBar', 23).should == 42
    stream.sent_data.should == [2, 1, 1, 'fooBar', 23]
  end

  it 'returns new remote objects' do
    ro
    stream.callback = lambda {ro.send(:receive, MockMessage.new(2, 0, 1, 42, ""))}
    new_ro = ro.call_rom('foo')
    new_ro.id.should == 42
  end

  it 'receives notifications' do
    ro.should_receive(:notification).with("foo", 42)
    ro.send(:receive, MockMessage.new(3, "foo", 42))
  end
end
