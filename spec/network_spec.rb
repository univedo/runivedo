require "spec_helper"

describe Runivedo::UConnection do
  describe "sending" do
    let(:connection) { Runivedo::UConnection.new(nil) }

    it "sends null" do
      connection.send(:send_impl, nil).should == "\x00"
    end

    it "sends bools" do
      connection.send(:send_impl, true).should == "\x01\x01"
      connection.send(:send_impl, false).should == "\x01\x00"
    end

    it "sends integers" do
      connection.send(:send_impl, 42).should == "\x0D\x2A" + "\x00" * 7
    end

    it "sends floats" do
      connection.send(:send_impl, 8.0e-323).should == "\x15\x10" + "\x00" * 7
    end

    it "sends strings" do
      connection.send(:send_impl, "foobar").should == "\x1e\x06\x00\x00\x00foobar"
    end
  end

  describe "receiving" do
    let(:connection) { Runivedo::UConnection.new(nil) }

    it "receives null" do
      connection.instance_variable_set(:@receive_buffer, "\x00")
      connection.receive.should == nil
    end

    it "receives bools" do
      connection.instance_variable_set(:@receive_buffer, "\x01\x00")
      connection.receive.should == false
      connection.instance_variable_set(:@receive_buffer, "\x01\x01")
      connection.receive.should == true
    end

    it "receives integers" do
      {10 => 1, 11 => 2, 12 => 4, 13 => 8, 15 => 1, 16 => 2, 17 => 4, 18 => 8}.each_pair do |i, s|
        connection.instance_variable_set(:@receive_buffer, [i].pack("C") + "\x2A" + "\x00" * (s-1))
        connection.receive.should == 42
      end
    end

    it "receives floats" do
      connection.instance_variable_set(:@receive_buffer, "\x14\x10" + "\x00" * 3)
      connection.receive.should == 2.2420775429197073e-44
      connection.instance_variable_set(:@receive_buffer, "\x15\x10" + "\x00" * 7)
      connection.receive.should == 8.0e-323
    end

    it "receives strings" do
      connection.instance_variable_set(:@receive_buffer, "\x1e\x06\x00\x00\x00foobar")
      connection.receive.should == "foobar"
      connection.instance_variable_set(:@receive_buffer, "\x1f\x06\x00\x00\x00f\x00o\x00o\x00b\x00a\x00r\x00")
      connection.receive.should == "foobar"
    end
  end
end
