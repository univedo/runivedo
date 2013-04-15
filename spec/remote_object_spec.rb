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
  let(:connection) { c = double(:connection); c.stub(:register_ro); c }
  let(:ro) { Runivedo::RemoteObject.new(stream: stream, connection: connection, id: 2) }

  it 'does rom calls' do
    ro
    msg = double(:msg)
    msg.stub(:read).and_return(2, 0, 0, 42)
    stream.callback = lambda {ro.send(:receive, msg)}
    ro.foo.should == 42
    stream.sent_data.should == [2, 1, 0, 'foo']
    # Second call
    stream.sent_data.clear
    msg = double(:msg)
    msg.stub(:read).and_return(2, 1, 0, 42)
    stream.callback = lambda {ro.send(:receive, msg)}
    ro.foo_bar(23).should == 42
    stream.sent_data.should == [2, 1, 1, 'fooBar', 23]
  end

  it 'returns new remote objects' do
    ro
    msg = double(:msg)
    msg.stub(:read).and_return(2, 0, 1, 42, "")
    stream.callback = lambda {ro.send(:receive, msg)}
    new_ro = ro.foo
    new_ro.id.should == 42
  end
end
