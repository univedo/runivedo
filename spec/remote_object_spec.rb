require "spec_helper"

class MockStream
  attr_accessor :callback, :sent_data

  def send_message(&block)
    @sent_data ||= []
    yield @sent_data
    @callback.call if @callback
  end
end

describe Runivedo::RemoteObject do
  let(:stream) { MockStream.new }
  let(:ro) { Runivedo::RemoteObject.new(stream: stream, connection: nil, id: 42) }

  it 'does rom calls' do
    ro
    msg = double(:msg)
    msg.stub(:read).and_return(2, 0, 0, 42)
    stream.callback = lambda {ro.send(:receive, msg)}
    ro.foo.should == 42
    stream.sent_data.should == [42, 1, 0, 'foo']
    # Second call
    stream.sent_data.clear
    msg = double(:msg)
    msg.stub(:read).and_return(2, 1, 0, 42)
    stream.callback = lambda {ro.send(:receive, msg)}
    ro.foo_bar(23).should == 42
    stream.sent_data.should == [42, 1, 1, 'fooBar', 23]
  end
end
