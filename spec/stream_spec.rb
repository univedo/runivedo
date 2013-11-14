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
      message << 8.0e-323
      message.buffer.should == "\xfb\x10".b + "\x00".b * 7
    end

    it "sends strings" do
      message << "foobar"
      message.buffer.should == "\x66foobar"
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
      message << {"bar" => false, "foo" => true}
      message.buffer.should == "\xa2\x63bar\xf4\x63foo\xf5".b
    end

    it 'sends uuids' do
      uuid = UUIDTools::UUID.random_create
      message << uuid
      message.buffer.should == "\xc7\x50".b + uuid.raw.b
    end

    it 'receives datetimes' do
      time = Time.at(1366190677)
      message << time
      message.buffer.should == "\xc8\x1b\x00\x04\xDA\x8B\x0D\xFF\x7F\x40".b
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
      message = Runivedo::Stream::Message.new("\xfa\x10".b + "\x00".b * 3)
      message.read.should == 2.2420775429197073e-44
      message = Runivedo::Stream::Message.new("\xfb\x10".b + "\x00".b * 7)
      message.read.should == 8.0e-323
    end

    it 'receives decimals' do
      message = Runivedo::Stream::Message.new("\xc4\x82\x18\x2a\x20".b)
      message.read.should == BigDecimal.new("4.2")
    end

    it "receives strings" do
      message = Runivedo::Stream::Message.new("\x66foobar".b)
      message.read.should == "foobar"
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
      message = Runivedo::Stream::Message.new("\xc9\x1b\x00\x04\xDA\x8B\x0D\xFF\x7F\x40".b)
      message.read.should == Time.at(1366190677)
    end

    it 'receives times' do
      message = Runivedo::Stream::Message.new("\xc8\x1b\x00\x04\xDA\x8B\x0D\xFF\x7F\x40".b)
      message.read.should == Time.at(1366190677)
    end

    it 'receives uuids' do
      uuid = UUIDTools::UUID.random_create
      message = Runivedo::Stream::Message.new("\xc7\x50".b + uuid.raw)
      message.read.should == uuid
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

    it "works for floats" do
      message << 42.23
      message_recv.read.should == 42.23
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
