require "test_helper"

class SessionTest < MiniTest::Test
  def setup
    @session = Runivedo::Session.new TEST_URL, TEST_AUTH
  end

  def teardown
    @session.close unless @session.closed?
  end

  def ping(v)
    assert_equal v, @session.ping(v), "pings #{v.inspect}"
  end

  def test_connect
    assert !@session.closed?
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
    @session.close
    assert @session.closed?
  end

  def test_error_closed
    @session.close
    assert_raises Runivedo::ConnectionError do
      @session.ping("foo")
    end
  end
end
