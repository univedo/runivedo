module Runivedo
  class VariantStream
    include Runivedo::Variant

    def initialize(io)
      @io = io
    end

    def has_data?
      !@io.eof?
    end

    def read
      raise 'message is empty' unless has_data?
      read_impl
    end

    private

    def get_bytes(count, pack_opts)
      s = @io.read(count)
      if s.size < count
        raise "message finished"
      end
      s.slice!(0, count).unpack(pack_opts)[0]
    end
  end
end
