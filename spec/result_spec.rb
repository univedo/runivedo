require "spec_helper"

describe Runivedo::UResult do
  let(:connection) { MockConnection.new }

  context "when running simple queries" do
    it "sends the query and receives affected rows" do
      connection.recv_data << CODE_ACK
      connection.recv_data << 42
      connection.recv_data << 0
      connection.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(connection, "SELECT answer FROM universe")
      r.run
      r.affected_rows.should == 42
      r.rows.should == []
      connection.sent_data.should == [CODE_SQL, "SELECT answer FROM universe", 0]
    end

    it 'sends bindings' do
      connection.recv_data << CODE_ACK
      connection.recv_data << 42
      connection.recv_data << 0
      connection.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(connection, "SELECT answer FROM :where", where: "universe")
      r.run
      connection.sent_data.should == [CODE_SQL, "SELECT answer FROM :where", 1, "where", "universe"]
    end

    it "receives one result" do
      connection.recv_data << CODE_ACK
      connection.recv_data << 42
      connection.recv_data << 2
      connection.recv_data << "c1"
      connection.recv_data << "c2"
      connection.recv_data << CODE_RESULT_MORE
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(connection, nil)
      r.run
      r.rows.count.should == 1
      r.rows[0].should == ["foo", "bar"]
      r.columns.should == ["c1", "c2"]
      r.each { |row| row.should == ["foo", "bar"] }
    end

    it "receives multiple results" do
      connection.recv_data << CODE_ACK
      connection.recv_data << 42
      connection.recv_data << 2
      connection.recv_data << "c1"
      connection.recv_data << "c2"
      connection.recv_data << CODE_RESULT_MORE
      connection.recv_data << "foo"
      connection.recv_data << "bar"
      connection.recv_data << CODE_RESULT_MORE
      connection.recv_data << "fu"
      connection.recv_data << "baz"
      connection.recv_data << CODE_RESULT_CLOSED
      r = Runivedo::UResult.new(connection, nil)
      r.run
      r.rows.count.should == 2
      r.rows[0].should == ["foo", "bar"]
      r.rows[1].should == ["fu", "baz"]
    end
  end
end
