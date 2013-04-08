require "spec_helper"

describe Runivedo::UResult do
  let(:stream) { MockConnection.new }

  context "when running simple queries" do
    it "sends the query and receives affected rows" do
      stream.recv_data << CODE_ACK
      stream.recv_data << 42
      stream.recv_data << 0
      stream.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(stream, "SELECT answer FROM universe")
      r.run
      r.affected_rows.should == 42
      r.rows.should == []
      stream.sent_data.should == [CODE_SQL, "SELECT answer FROM universe", 0]
    end

    it 'sends bindings' do
      stream.recv_data << CODE_ACK
      stream.recv_data << 42
      stream.recv_data << 0
      stream.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(stream, "SELECT answer FROM :where", where: "universe")
      r.run
      stream.sent_data.should == [CODE_SQL, "SELECT answer FROM :where", 1, "where", "universe"]
    end

    it "receives one result" do
      stream.recv_data << CODE_ACK
      stream.recv_data << 42
      stream.recv_data << 2
      stream.recv_data << "c1"
      stream.recv_data << "c2"
      stream.recv_data << CODE_RESULT_MORE
      stream.recv_data << "foo"
      stream.recv_data << "bar"
      stream.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(stream, nil)
      r.run
      r.rows.count.should == 1
      r.rows[0].should == ["foo", "bar"]
      r.columns.should == ["c1", "c2"]
      r.each { |row| row.should == ["foo", "bar"] }
    end

    it "receives multiple results" do
      stream.recv_data << CODE_ACK
      stream.recv_data << 42
      stream.recv_data << 2
      stream.recv_data << "c1"
      stream.recv_data << "c2"
      stream.recv_data << CODE_RESULT_MORE
      stream.recv_data << "foo"
      stream.recv_data << "bar"
      stream.recv_data << CODE_RESULT_MORE
      stream.recv_data << "fu"
      stream.recv_data << "baz"
      stream.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(stream, nil)
      r.run
      r.rows.count.should == 2
      r.rows[0].should == ["foo", "bar"]
      r.rows[1].should == ["fu", "baz"]
    end
  end
end
