require "test_helper"

class ConnectionTest < MiniTest::Test
  def setup
    @connection = Runivedo::Connection.new TEST_URL
    @session = @connection.get_session TEST_BUCKET, TEST_AUTH
  end

  def teardown
    @connection.close unless @connection.closed?
  end

  def ping(v)
    assert_equal v, @session.ping(v), "pings #{v.inspect}"
  end

  def test_connect
    assert !@connection.closed?
  end

  def test_pings_null
    ping nil
    ping true
    ping false
    ping 42
    ping -42
    ping 1.1
    ping "foobar"
    ping [1, 2]
    ping Time.now
  end

  def test_close
    @connection.close
    assert @connection.closed?
  end

  def test_error_closed
    @connection.close
    assert_raises Runivedo::ConnectionError do
      @session.ping("foo")
    end
  end
end
