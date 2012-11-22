require "spec_helper"

describe Runivedo::UResult do
  let(:connection) { MockConnection.new }

  context "when running simple queries" do
    it "sends the query" do
      connection.recv_data << CODE_RESULT
      r = Runivedo::UResult.new(connection, "SELECT answer FROM universe")
      r.run
      connection.sent_data.should == [CODE_SQL, "SELECT answer FROM universe", 0]
    end

    it "receives affected rows" do
      connection.recv_data << CODE_MODIFICATION
      connection.recv_data << 42
      r = Runivedo::UResult.new(connection, nil)
      r.run
      r.affected_rows.should == 42
    end

    it "receives zero results" do
      connection.recv_data << CODE_RESULT
      connection.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(connection, nil)
      r.next_row.should be_nil
      r.complete.should be_true
    end

    it "receives one result" do
      connection.recv_data << CODE_RESULT
      connection.recv_data << CODE_RESULT_MORE
      connection.recv_data << 2
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(connection, nil)
      r.next_row.should == ["foo", "bar"]
      r.next_row.should be_nil
      r.complete.should be_true
    end

    it "receives multiple results" do
      connection.recv_data << CODE_RESULT
      connection.recv_data << CODE_RESULT_MORE
      connection.recv_data << 2
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << CODE_RESULT_MORE
      connection.recv_data << 2
      connection.recv_data << "fu"
      connection.recv_data << "baz"
      connection.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(connection, nil)
      r.next_row.should == ["foo", "bar"]
      r.next_row.should == ["fu", "baz"]
      r.next_row.should be_nil
      r.complete.should be_true
    end

    it "receives one result in enumerator" do
      connection.recv_data << CODE_RESULT
      connection.recv_data << CODE_RESULT_MORE
      connection.recv_data << 2
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(connection, nil)
      r.each { |r| r.should == ["foo", "bar"] }
      r.next_row.should be_nil
      r.complete.should be_true
    end
  end
end
