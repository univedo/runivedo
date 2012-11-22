module Runivedo
  class RunivedoSqlError < RuntimeError
    def initialize(description)
      super(description)
    end
  end
end
