require "test_helper"

class SqlTest < MiniTest::Test
  def setup
    @connection = Runivedo::Connection.new TEST_URL
    @session = @connection.get_session TEST_BUCKET, TEST_AUTH
    @session.apply_uts IO.read("Test Perspective.xml")
    @perspective = @session.get_perspective "cefb4ed2-4ce3-4825-8550-b68a3c142f0a"
  end

  def teardown
    @connection.close
  end

  def test_connection
    assert !@perspective.closed?
  end

  def test_empty_select
    @perspective.query do |query|
      query.prepare "select * from dummy where dummy_uuid = '1AF6B99E-5908-4516-A5FA-B22AFD27E003'" do |stmt|
        stmt.execute do |result|
          assert [], result.to_a
        end
      end
    end
  end

  def test_column_names
    @perspective.query do |query|
      query.prepare "select dummy_id, dummy_int8 from dummy" do |stmt|
        assert %w(dummy_id dummy_int8), stmt.column_names
      end
    end
  end

  def test_system_select
    @session.get_perspective("6e5a3a08-9bb0-4d92-ad04-7c6fed3874fa") do |persp|
      persp.query do |query|
        query.prepare "select * from fields" do |stmt|
          stmt.execute do |result|
            assert result.to_a.count > 100
          end
        end
      end
    end
  end

  def test_selects
    @perspective.query do |query|
      query.prepare "select * from fields_inclusive" do |stmt|
        stmt.execute do |result|
          assert result.to_a.count > 100
          assert result.last_inserted_id.nil?
          assert result.num_affected_rows.nil?
        end
      end
    end
  end

  def test_inserts
    id = nil
    @perspective.query do |query|
      query.prepare "insert into dummy (dummy_int8) values (?)" do |stmt|
        stmt.execute(0 => 42) do |result|
          id = result.last_inserted_id
        end
      end
      assert !id.nil?
      query.prepare "select id, dummy_int8 from dummy where id = ?" do |stmt|
        stmt.execute(0 => id) do |result|
          assert_equal [[id, 42]], result.to_a
        end
      end
    end
  end
end
