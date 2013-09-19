require "spec_helper"

describe Runivedo::RemoteObject do
  let(:stream) { MockStream.new }
  let(:connection) { c = double(:connection); c.stub(:register_ro_instance); c.stub(:stream).and_return(stream); c }
  let(:ro) { Runivedo::RemoteObject.new(connection: connection, id: 2) }

  it 'does rom calls' do
    stream.callback = lambda {Thread.new{ro.send(:receive, MockMessage.new(2, 0, 0, 42))}}
    ro.call_rom('foo').should == 42
    stream.sent_data.should == [2, 1, 0, 'foo']
    # Second call
    stream.sent_data.clear
    stream.callback = lambda {Thread.new{ro.send(:receive, MockMessage.new(2, 1, 0, 42))}}
    ro.call_rom('bar', 23).should == 42
    stream.sent_data.should == [2, 1, 1, 'bar', 23]
  end

  # it 'returns new remote objects' do
  #   stream.callback = lambda {ro.send(:receive, MockMessage.new(2, 0, 1, 42, ""))}
  #   new_ro = ro.call_rom('foo')
  #   new_ro.id.should == 42
  # end

  it 'receives notifications' do
    ro.should_receive(:notification).with("foo", 42)
    ro.send(:receive, MockMessage.new(3, "foo", 42))
  end

  # it 'returns registered remote object classes' do
  #   Foo = Class.new(Runivedo::RemoteObject)
  #   Runivedo::RemoteObject.register_ro_class('Foo', Foo)
  #   stream.callback = lambda {ro.send(:receive, MockMessage.new(2, 0, 1, [42, "Foo"]))}
  #   new_ro = ro.call_rom('foo')
  #   new_ro.id.should == 42
  #   new_ro.should be_a Foo
  #   Runivedo::RemoteObject.unregister_ro_class('Foo')
  # end

  # it 'receives results' do
  #   stream.callback = lambda {ro.send(:receive, MockMessage.new(2, 0, 1, [42, "result"]))}
  #   new_ro = ro.call_rom('foo')
  #   new_ro.id.should == 42
  #   new_ro.should be_a Runivedo::Result
  # end
end
