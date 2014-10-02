require "test_helper"

class MockConnection
  attr_accessor :msg, :onmsg

  def send_message(msg)
    @msg = msg
    @onmsg.call if @onmsg
  end

  def delete_ro(id); end
end

class RemoteObjectTest < MiniTest::Test
  def test_sending_notifications
    connection = MockConnection.new
    ro = Runivedo::RemoteObject.new(connection, 23)
    ro.send_notification "foo", 1, "2", 3
    assert_equal [23, 3, "foo", [1, "2", 3]], connection.msg
  end

  def test_receiving_notifications
    res = nil
    connection = MockConnection.new
    ro = Runivedo::RemoteObject.new(connection, 23)
    ro.on("foo") {|a, b, c| res = [a, b, c]}
    ro.send :receive, [3, "foo", [1, "2", 3]]
    assert_equal [1, "2", 3], res
  end

  def test_rom_calls
    connection = MockConnection.new
    ro = Runivedo::RemoteObject.new(connection, 23)
    connection.onmsg = -> {ro.send :receive, [2, 0, 0, 42]}
    assert_equal 42, ro.call_rom("foo", 1, "2", 3)
    assert_equal [23, 1, 0, "foo", [1, "2", 3]], connection.msg
  end

  def test_rom_errors
    assert_raises Runivedo::SqlError do
      connection = MockConnection.new
      ro = Runivedo::RemoteObject.new(connection, 23)
      connection.onmsg = -> {ro.send :receive, [2, 0, 1, "boom"]}
      assert_equal 42, ro.call_rom("foo", 1, "2", 3)
      assert_equal [23, 1, 0, "foo", [1, "2", 3]], connection.msg
    end
  end

  def test_closes
    connection = MockConnection.new
    ro = Runivedo::RemoteObject.new(connection, 23)
    ro.close
    assert_equal [23, 4], connection.msg
  end
end
