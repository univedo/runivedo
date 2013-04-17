require "spec_helper"

describe Runivedo::Stream do
  describe "sending" do
    let(:message) { Runivedo::Stream::Message.new }

    it "sends null" do
      message << nil
      message.buffer.should == "\x00"
    end

    it "sends bools" do
      message << true
      message << false
      message.buffer.should == "\x01\x01\x01\x00"
    end

    it "sends integers" do
      message << 42
      message.buffer.should == "\x0D\x2A" + "\x00" * 7
    end

    it "sends floats" do
      message << 8.0e-323
      message.buffer.should == "\x15\x10" + "\x00" * 7
    end

    it "sends strings" do
      message << "foobar"
      message.buffer.should == "\x1e\x06\x00\x00\x00foobar"
    end

    it "sends arrays" do
      message << %w(foo bar)
      message.buffer.should == "\x3c\x02\x00\x00\x00\x1e\x03\x00\x00\x00foo\x1e\x03\x00\x00\x00bar"
    end

    it "sends maps" do
      message << {"foo" => true, "bar" => false}
      message.buffer.should == "\x3d\x02\x00\x00\x00\x1e\x03\x00\x00\x00foo\x01\x01\x1e\x03\x00\x00\x00bar\x01\x00"
    end

    it 'sends uuids' do
      uuid = UUIDTools::UUID.random_create
      message << uuid
      message.buffer.should == "\x2a" + uuid.raw
    end
  end

  describe "receiving" do
    let(:message) { Runivedo::Stream::Message.new }

    it "receives null" do
      message.instance_variable_set(:@buffer, "\x00")
      message.read.should == nil
    end

    it "receives bools" do
      message.instance_variable_set(:@buffer, "\x01\x00")
      message.read.should == false
      message.instance_variable_set(:@buffer, "\x01\x01")
      message.read.should == true
    end

    it "receives integers" do
      {10 => 1, 11 => 2, 12 => 4, 13 => 8, 15 => 1, 16 => 2, 17 => 4, 18 => 8}.each_pair do |i, s|
        message.instance_variable_set(:@buffer, [i].pack("C") + "\x2A" + "\x00" * (s-1))
        message.read.should == 42
      end
    end

    it "receives floats" do
      message.instance_variable_set(:@buffer, "\x14\x10" + "\x00" * 3)
      message.read.should == 2.2420775429197073e-44
      message.instance_variable_set(:@buffer, "\x15\x10" + "\x00" * 7)
      message.read.should == 8.0e-323
    end

    it "receives strings" do
      message.instance_variable_set(:@buffer, "\x1e\x06\x00\x00\x00foobar")
      message.read.should == "foobar"
      message.instance_variable_set(:@buffer, "\x1f\x06\x00\x00\x00f\x00o\x00o\x00b\x00a\x00r\x00")
      message.read.should == "foobar"
    end

    it "receives arrays" do
      message.instance_variable_set(:@buffer, "\x3c\x02\x00\x00\x00\x1e\x03\x00\x00\x00foo\x1e\x03\x00\x00\x00bar")
      message.read.should == %w(foo bar)
    end

    it "receives maps" do
      message.instance_variable_set(:@buffer, "\x3d\x02\x00\x00\x00\x1e\x03\x00\x00\x00foo\x0a\x01\x1e\x03\x00\x00\x00bar\x0a\x02")
      message.read.should == {"foo" => 1, "bar" => 2}
    end

    it "receives remote object ids" do
      message.instance_variable_set(:@buffer, "\x2d\x2a\x00\x00\x00\x1e\x03\x00\x00\x00foo")
      message.read.should == [42, "foo"]
    end

    it 'receives records' do
      message.instance_variable_set(:@buffer, "\x29\x01\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00")
      message.read.should == [1, 2]
    end

    it 'receives datetimes' do
      message.instance_variable_set(:@buffer, "\x33\x40\x7F\xFF\x0D\x8B\xDA\x04\x00")
      message.read.should == Time.at(1366190677).to_datetime
    end

    it 'receives uuids' do
      uuid = UUIDTools::UUID.random_create
      message.instance_variable_set(:@buffer, "\x2a" + uuid.raw)
      message.read.should == uuid
    end
  end

  describe "sending and receiving" do
    let(:message) { Runivedo::Stream::Message.new }

    it "works for null" do
      message << nil
      message.read.should == nil
    end

    it "works for bools" do
      message << true
      message.read.should == true
      message << false
      message.read.should == false
    end

    it "works for ints" do
      message << 42
      message.read.should == 42
    end

    it "works for floats" do
      message << 42.23
      message.read.should == 42.23
    end

    it "works for strings" do
      message << "foobar"
      message.read.should == "foobar"
    end

    it "works for arrays" do
      message << %w(foo bar)
      message.read.should == %w(foo bar)
    end

    it "works for maps" do
      message << {"foo" => 1, "foo" => 2}
      message.read.should == {"foo" => 1, "foo" => 2}
    end

    it "works for uuids" do
      uuid = UUIDTools::UUID.random_create
      message << uuid
      message.read.should == uuid
    end
  end
end
