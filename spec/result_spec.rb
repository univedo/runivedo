require 'spec_helper'

describe Runivedo::Result do
  let(:connection) { c = double(:connection); c.stub(:register_ro_instance); c.stub(:stream); c }
  let(:result) { Runivedo::Result.new(connection: connection) }

  it 'gets number of rows' do
    result.send(:notification, 'finished', 42)
    result.number_of_rows.should == 42
  end

  it 'gets rows' do
    result.send(:notification, 'nextRow', %w(foo bar))
    result.send(:notification, 'nextRow', %w(fu baz))
    result.send(:notification, 'finished')
    result.to_a.should == [%w(foo bar), %w(fu baz)]
  end

  it 'gets errors' do
    result.send(:notification, 'error')
    lambda { result.to_a.should }.should raise_error(Exception)
  end
end
