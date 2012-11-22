module Runivedo
  module Protocol
    PROTOCOL_VERSION = 1
    CODE_ACK = 0
    CODE_BEGIN = 110
    CODE_COMMIT = 111
    CODE_ROLLBACK = 112
    CODE_SQL = 100
    CODE_RESULT_MORE = 10
    CODE_RESULT_CLOSED = 11
  end
end