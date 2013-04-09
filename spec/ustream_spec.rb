require "spec_helper"

describe Runivedo::UStream do
  describe "sending" do
    let(:stream) { Runivedo::UStream.new }

    it "sends null" do
      stream.send(:send_impl, nil).should == "\x00"
    end

    it "sends bools" do
      stream.send(:send_impl, true).should == "\x01\x01"
      stream.send(:send_impl, false).should == "\x01\x00"
    end

    it "sends integers" do
      stream.send(:send_impl, 42).should == "\x0D\x2A" + "\x00" * 7
    end

    it "sends floats" do
      stream.send(:send_impl, 8.0e-323).should == "\x15\x10" + "\x00" * 7
    end

    it "sends strings" do
      stream.send(:send_impl, "foobar").should == "\x1e\x06\x00\x00\x00foobar"
    end
  end

  describe "receiving" do
    let(:stream) { Runivedo::UStream.new }

    it "receives null" do
      stream.instance_variable_set(:@receive_buffer, "\x00")
      stream.receive.should == nil
    end

    it "receives bools" do
      stream.instance_variable_set(:@receive_buffer, "\x01\x00")
      stream.receive.should == false
      stream.instance_variable_set(:@receive_buffer, "\x01\x01")
      stream.receive.should == true
    end

    it "receives integers" do
      {10 => 1, 11 => 2, 12 => 4, 13 => 8, 15 => 1, 16 => 2, 17 => 4, 18 => 8}.each_pair do |i, s|
        stream.instance_variable_set(:@receive_buffer, [i].pack("C") + "\x2A" + "\x00" * (s-1))
        stream.receive.should == 42
      end
    end

    it "receives floats" do
      stream.instance_variable_set(:@receive_buffer, "\x14\x10" + "\x00" * 3)
      stream.receive.should == 2.2420775429197073e-44
      stream.instance_variable_set(:@receive_buffer, "\x15\x10" + "\x00" * 7)
      stream.receive.should == 8.0e-323
    end

    it "receives strings" do
      stream.instance_variable_set(:@receive_buffer, "\x1e\x06\x00\x00\x00foobar")
      stream.receive.should == "foobar"
      stream.instance_variable_set(:@receive_buffer, "\x1f\x06\x00\x00\x00f\x00o\x00o\x00b\x00a\x00r\x00")
      stream.receive.should == "foobar"
    end

    it "receives lists" do
      stream.instance_variable_set(:@receive_buffer, "\x3c\x02\x00\x00\x00\x1e\x03\x00\x00\x00foo\x1e\x03\x00\x00\x00bar")
      stream.receive.should == %w(foo bar)
    end

    it "receives maps" do
      stream.instance_variable_set(:@receive_buffer, "\x3d\x02\x00\x00\x00\x1e\x03\x00\x00\x00foo\x0a\x01\x1e\x03\x00\x00\x00bar\x0a\x02")
      stream.receive.should == {"foo" => 1, "bar" => 2}
    end
  end

  describe "sending and receiving" do
    let(:stream) { Runivedo::UStream.new }

    it "works for null" do
      stream.instance_variable_set(:@receive_buffer, stream.send(:send_impl, nil))
      stream.receive.should == nil
    end

    it "works for bools" do
      stream.instance_variable_set(:@receive_buffer, stream.send(:send_impl, true))
      stream.receive.should == true
      stream.instance_variable_set(:@receive_buffer, stream.send(:send_impl, false))
      stream.receive.should == false
    end

    it "works for ints" do
      stream.instance_variable_set(:@receive_buffer, stream.send(:send_impl, 42))
      stream.receive.should == 42
    end

    it "works for floats" do
      stream.instance_variable_set(:@receive_buffer, stream.send(:send_impl, 42.23))
      stream.receive.should == 42.23
    end

    it "works for strings" do
      stream.instance_variable_set(:@receive_buffer, stream.send(:send_impl, "foobar"))
      stream.receive.should == "foobar"
    end
  end
end
