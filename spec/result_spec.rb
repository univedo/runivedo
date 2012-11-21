require "spec_helper"

describe Runivedo::UResult do
  let(:connection) { MockConnection.new }

  context "when running simple queries" do
    it "sends the query" do
      connection.recv_data << 10
      r = Runivedo::UResult.new(connection, "SELECT answer FROM universe")
      r.run
      connection.sent_data[-1].should == "SELECT answer FROM universe"
    end

    it "receives affected rows" do
      connection.recv_data << 11
      connection.recv_data << 42
      r = Runivedo::UResult.new(connection, nil)
      r.run
      r.affected_rows.should == 42
    end

    it "receives zero results" do
      connection.recv_data << 10
      connection.recv_data << 21
      r = Runivedo::UResult.new(connection, nil)
      r.next_row.should be_nil
      r.complete.should be_true
    end

    it "receives one result" do
      connection.recv_data << 10
      connection.recv_data << 20
      connection.recv_data << 2
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << 21
      r = Runivedo::UResult.new(connection, nil)
      r.next_row.should == ["foo", "bar"]
      r.next_row.should be_nil
      r.complete.should be_true
    end

    it "receives multiple results" do
      connection.recv_data << 10
      connection.recv_data << 20
      connection.recv_data << 2
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << 20
      connection.recv_data << 2
      connection.recv_data << "fu"
      connection.recv_data << "baz"
      connection.recv_data << 21
      r = Runivedo::UResult.new(connection, nil)
      r.next_row.should == ["foo", "bar"]
      r.next_row.should == ["fu", "baz"]
      r.next_row.should be_nil
      r.complete.should be_true
    end

    it "receives one result in enumerator" do
      connection.recv_data << 10
      connection.recv_data << 20
      connection.recv_data << 2
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << 21
      r = Runivedo::UResult.new(connection, nil)
      r.each { |r| r.should == ["foo", "bar"] }
      r.next_row.should be_nil
      r.complete.should be_true
    end
  end
end
