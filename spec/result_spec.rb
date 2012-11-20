require "spec_helper"

describe Runivedo::UResult do
  context "when running simple queries" do
    let(:connection) { MockConnection.new }

    it "sends the query" do
      connection.recv_data << 0
      r = Runivedo::UResult.new(connection, "SELECT answer FROM universe")
      r.run
      connection.sent_data.should == ["SELECT answer FROM universe"]
    end

    it "receives affected rows" do
      connection.recv_data << 1
      connection.recv_data << 42
      r = Runivedo::UResult.new(connection, nil)
      r.run
      r.affected_rows.should == 42
    end

    it "receives errors" do
      connection.recv_data << 10
      connection.recv_data << "invalid question"
      r = Runivedo::UResult.new(connection, nil)
      expect { r.run }.to raise_error("invalid question")
    end
  end
end
