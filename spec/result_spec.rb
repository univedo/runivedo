require 'spec_helper'

describe Runivedo::Result do
  let(:connection) { c = double(:connection); c.stub(:register_ro_instance); c.stub(:stream); c }
  let(:result) { Runivedo::Result.new(connection: connection) }

  it 'gets number of rows' do
    result.send(:notification, 'setNTuplesAffected', 42)
    result.num_affected_rows.should == 42
  end

  it 'gets rows' do
    result.send(:notification, 'appendTuple', %w(foo bar))
    result.send(:notification, 'appendTuple', %w(fu baz))
    result.send(:notification, 'setCompleted')
    result.to_a.should == [%w(foo bar), %w(fu baz)]
  end

  it 'gets errors' do
    result.send(:notification, 'setErrorMessage', 'foobar')
    lambda { result.to_a.should }.should raise_error(Exception, /foobar/)
  end
end
