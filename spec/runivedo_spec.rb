require "spec_helper"

describe Runivedo::Runivedo do
  context "when running simple queries" do
    let(:connection) { MockConnection.new }

    it "executes queries" do
      connection.recv_data << 1
      connection.recv_data << 42
      r = Runivedo::Runivedo.new(nil)
      r.instance_variable_set(:@connection, connection)
      results = r.execute("SELECT answer FROM universe")
      connection.sent_data.should == ["SELECT answer FROM universe"]
      results.complete.should be_true
      results.affected_rows.should == 42
    end

    it "executes queries with block" do
      connection.recv_data << 0
      connection.recv_data << 0
      connection.recv_data << 2
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << 1
      r = Runivedo::Runivedo.new(nil)
      r.instance_variable_set(:@connection, connection)
      result = r.execute("SELECT answer FROM universe") do |row|
        row.should == ["foo", "bar"]
      end
      result.complete.should be_true
    end
  end
end
