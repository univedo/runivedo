require 'rspec'
require 'runivedo'
require 'timeout'

include Runivedo::Protocol

RSpec.configure do |c|
  c.around(:each) do |example|
    Timeout::timeout(1) {
      example.run
    }
  end
end
