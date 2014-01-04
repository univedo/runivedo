require "spec_helper"

describe Runivedo::Stream do
  describe "sending" do
    let(:message) { Runivedo::Stream::Message.new }

    it "sends null" do
      message << nil
      message.buffer.should == "\xF6".b
    end

    it "sends bools" do
      message << true
      message << false
      message.buffer.should == "\xF5\xF4".b
    end

    it "sends integers" do
      message << 42
      message.buffer.should == "\x18\x2a".b
    end

    it "sends floats" do
      message << 1.0e300
      message.buffer.should == "\xfb\x7e\x37\xe4\x3c\x88\x00\x75\x9c".b
    end

    it "sends strings" do
      message << "foobar"
      message.buffer.should == "\x66foobar".b
    end

    it "sends blobs" do
      message << "f\xc3\x28bar".b
      message.buffer.should == "\x46f\xc3\x28bar".b
    end

    it "sends symbols as strings" do
      message << :foobar
      message.buffer.should == "\x66foobar".b
    end

    it "sends arrays" do
      message << %w(foo bar)
      message.buffer.should == "\x82\x63foo\x63bar".b
    end

    it "sends maps" do
      message << {"bar" => false, :foo => true}
      message.buffer.should == "\xa2\x63bar\xf4\x63foo\xf5".b
    end

    it 'sends uuids' do
      uuid = UUIDTools::UUID.random_create
      message << uuid
      message.buffer.should == "\xc7\x50".b + uuid.raw.b
    end

    it 'sends datetimes' do
      time = Time.iso8601("2013-03-21T20:04:00Z")
      message << time
      message.buffer.should == "\xc0\x78\x1b\x32\x30\x31\x33\x2d\x30\x33\x2d\x32\x31\x54\x32\x30\x3a\x30\x34\x3a\x30\x30.000000\x5a".b
      message.buffer = ""
      time = Time.iso8601("2013-03-21T20:04:00.000001Z")
      message << time
      message.buffer.should == "\xc0\x78\x1b\x32\x30\x31\x33\x2d\x30\x33\x2d\x32\x31\x54\x32\x30\x3a\x30\x34\x3a\x30\x30.000001\x5a".b
    end
  end

  describe "receiving" do
    it "receives null" do
      message = Runivedo::Stream::Message.new("\xf6".b)
      message.read.should == nil
    end

    it "receives bools" do
      message = Runivedo::Stream::Message.new("\xf5".b)
      message.read.should == true
      message = Runivedo::Stream::Message.new("\xf4".b)
      message.read.should == false
    end

    it "receives integers" do
      message = Runivedo::Stream::Message.new("\x18\x2a".b)
      message.read.should == 42
    end

    it "receives floats" do
      message = Runivedo::Stream::Message.new("\xfa\x47\xc3\x50\x00\x00")
      message.read.should == 100000.0
      message = Runivedo::Stream::Message.new("\xfb\x7e\x37\xe4\x3c\x88\x00\x75\x9c")
      message.read.should == 1.0e300
    end

    it 'receives decimals' do
      message = Runivedo::Stream::Message.new("\xc4\x82\x18\x2a\x20".b)
      message.read.should == BigDecimal.new("4.2")
    end

    it "receives strings" do
      message = Runivedo::Stream::Message.new("\x66foobar".b)
      s = message.read
      s.should == "foobar"
      s.encoding.should == Encoding::UTF_8
    end

    it "receives blobs" do
      message = Runivedo::Stream::Message.new("\x46foobar".b)
      s = message.read
      s.should == "foobar"
      s.encoding.should == Encoding::ASCII_8BIT
    end

    it "receives arrays" do
      message = Runivedo::Stream::Message.new("\x82\x63foo\x63bar".b)
      message.read.should == %w(foo bar)
    end

    it "receives maps" do
      message = Runivedo::Stream::Message.new("\xa2\x63bar\x02\x63foo\x01".b)
      message.read.should == {"bar" => 2, "foo" => 1}
    end

    it 'receives datetimes' do
      message = Runivedo::Stream::Message.new("\xc0\x74\x32\x30\x31\x33\x2d\x30\x33\x2d\x32\x31\x54\x32\x30\x3a\x30\x34\x3a\x30\x30\x5a".b)
      message.read.should == Time.iso8601("2013-03-21T20:04:00Z")
      message = Runivedo::Stream::Message.new("\xc0\x78\x1b\x32\x30\x31\x33\x2d\x30\x33\x2d\x32\x31\x54\x32\x30\x3a\x30\x34\x3a\x30\x30.000001\x5a".b)
      message.read.should == Time.iso8601("2013-03-21T20:04:00.000001Z")
    end

    it 'receives times' do
      message = Runivedo::Stream::Message.new("\xc1\x1a\x51\x4b\x67\xb0".b)
      message.read.should == Time.at(1363896240)
    end

    it 'receives uuids' do
      uuid = UUIDTools::UUID.random_create
      message = Runivedo::Stream::Message.new("\xc7\x50".b + uuid.raw)
      message.read.should == uuid
    end

    it 'receives records' do
      message = Runivedo::Stream::Message.new("\xc8\x18\x2a".b)
      message.read.should == 42
    end
  end

  describe "sending and receiving" do
    let(:message) { Runivedo::Stream::Message.new }
    let(:message_recv) { Runivedo::Stream::Message.new(message.instance_variable_get(:@buffer)) }

    it "works for null" do
      message << nil
      message_recv.read.should == nil
    end

    it "works for true" do
      message << true
      message_recv.read.should == true
    end

    it "works for false" do
      message << false
      message_recv.read.should == false
    end

    it "works for ints" do
      message << 42
      message_recv.read.should == 42
    end

    it "works for strings" do
      message << "foobar"
      message_recv.read.should == "foobar"
    end

    it "works for arrays" do
      message << %w(foo bar)
      message_recv.read.should == %w(foo bar)
    end

    it "works for maps" do
      message << {"foo" => 1, "foo" => 2}
      message_recv.read.should == {"foo" => 1, "foo" => 2}
    end

    it "works for null decimal" do
      dec = BigDecimal.new("0.00")
      message << dec
      message_recv.read.to_s('F').should == "0.0"
    end

    it "works for positive decimal" do
      dec = BigDecimal.new("4.3")
      message << dec
      message_recv.read.to_s('F').should == "4.3"
    end

    it "works for negative decimal" do
      dec = BigDecimal.new(43) / BigDecimal.new(-10)
      message << dec
      message_recv.read.to_s('F').should == "-4.3"
    end

    it "works for uuids" do
      uuid = UUIDTools::UUID.random_create
      message << uuid
      message_recv.read.should == uuid
    end
  end

  describe Runivedo::VariantStream do
    it "receives" do
      s = Runivedo::VariantStream.new(StringIO.new("\x18\x2a\x66foobar".b))
      s.read.should == 42
      s.read.should == "foobar"
      s.has_data?.should be_false
    end
  end
end