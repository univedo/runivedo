require "spec_helper"

describe Runivedo::RemoteObject do
  let(:stream) { MockStream.new }
  let(:ro) { Runivedo::RemoteObject.new(stream: stream, id: 42, app: 'appname', name: 'roname') }

  it 'sends instanciation' do
    ro
    stream.sent_data.should == [42, 4, 'appname', 'roname']
  end

  context 'rom calls' do
    it 'sends simple call' do
      ro
      stream.sent_data.clear
      ro.foo
      stream.sent_data.should == [42, 1, 0, 'foo']
    end

    it 'sends multiple calls' do
      ro
      stream.sent_data.clear
      ro.foo
      ro.bar
      stream.sent_data.should == [42, 1, 0, 'foo'] + [42, 1, 1, 'bar']
    end

    it 'sends parameters' do
      ro
      stream.sent_data.clear
      ro.foo('bar', 1)
      stream.sent_data.should == [42, 1, 0, 'foo', 'bar', 1]
    end

    it 'camelizes' do
      ro
      stream.sent_data.clear
      ro.foo_bar
      stream.sent_data.should == [42, 1, 0, 'fooBar']
    end
  end
end
