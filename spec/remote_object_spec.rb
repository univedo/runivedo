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
  let(:ro) { Runivedo::RemoteObject.new(stream: stream, id: 42, app: 'appname', name: 'roname') }
  let(:message) { d = double(:message); d.stub(:read).and_return(2, 0, 0, 42); d }
  let(:message2) { d = double(:message); d.stub(:read).and_return(2, 1, 0, 23); d }

  it 'sends instanciation' do
    ro
    stream.sent_data.should == [42, 4, 'appname', 'roname']
  end

  context 'rom calls' do
    it 'sends simple call' do
      ro
      stream.sent_data.clear
      stream.callback = lambda {ro.send(:receive, message)}
      ro.foo.should == 42
      stream.sent_data.should == [42, 1, 0, 'foo']
    end

    it 'sends multiple calls' do
      ro
      stream.sent_data.clear
      stream.callback = lambda {ro.send(:receive, message)}
      ro.foo.should == 42
      stream.callback = lambda {ro.send(:receive, message2)}
      ro.bar.should == 23
      stream.sent_data.should == [42, 1, 0, 'foo'] + [42, 1, 1, 'bar']
    end

    it 'sends parameters' do
      ro
      stream.sent_data.clear
      stream.callback = lambda {ro.send(:receive, message)}
      ro.foo('bar', 1).should == 42
      stream.sent_data.should == [42, 1, 0, 'foo', 'bar', 1]
    end

    it 'camelizes' do
      ro
      stream.sent_data.clear
      stream.callback = lambda {ro.send(:receive, message)}
      ro.foo_bar.should == 42
      stream.sent_data.should == [42, 1, 0, 'fooBar']
    end
  end
end
