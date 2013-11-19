require 'spec_helper'

describe Runivedo::Result do
  let(:connection) { c = double(:connection); c.stub(:register_ro_instance); c.stub(:stream); c }
  let(:result) { Runivedo::Result.new(connection: connection) }

  it 'gets errors' do
    result.send(:notification, 'setError', "foobar")
    lambda {result.to_a }.should raise_error(Runivedo::RunivedoSqlError, /foobar/)
    lambda {result.affected_rows }.should raise_error(Runivedo::RunivedoSqlError, /foobar/)
    lambda {result.num_affected_rows }.should raise_error(Runivedo::RunivedoSqlError, /foobar/)
    lambda {result.last_inserted_id }.should raise_error(Runivedo::RunivedoSqlError, /foobar/)
  end

  it 'gets rows' do
    result.send(:notification, 'appendRow', %w(foo bar))
    result.send(:notification, 'appendRow', %w(fu baz))
    result.send(:notification, 'setComplete')
    result.to_a.should == [%w(foo bar), %w(fu baz)]

    result.affected_rows.should be_nil
    result.num_affected_rows.should be_nil
    result.last_inserted_id.should be_nil
  end

  it 'gets affected records' do
    result.send(:notification, 'setAffectedRecords', [1, 2, 3])
    result.affected_rows.should == [1, 2, 3]
    result.num_affected_rows.should == 3

    result.last_inserted_id.should be_nil
    result.to_a.should be_empty
  end

  it 'gets last inserted id' do
    result.send(:notification, 'setRecord', 42)
    result.last_inserted_id.should == 42

    result.affected_rows.should be_nil
    result.num_affected_rows.should be_nil
    result.to_a.should be_empty
  end
end
