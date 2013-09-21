require "bigdecimal"

module Runivedo
  module Variant
    private

    def read_impl
      type = get_bytes(1, "C")
      case type
      when 0
        nil
      when 1
        get_bytes(1, "C") == 1 ? true : false
      when 5
        BigDecimal.new(get_bytes(1, "c")) / (10 ** get_bytes(1, "C"))
      when 6
        BigDecimal.new(get_bytes(2, "s")) / (10 ** get_bytes(1, "C"))
      when 7
        BigDecimal.new(get_bytes(4, "l")) / (10 ** get_bytes(1, "C"))
      when 8
        BigDecimal.new(get_bytes(8, "q")) / (10 ** get_bytes(1, "C"))
      when 10
        get_bytes(1, "c")
      when 11
        get_bytes(2, "s")
      when 12
        get_bytes(4, "l")
      when 13
        get_bytes(8, "q")
      when 15
        get_bytes(1, "C")
      when 16
        get_bytes(2, "S")
      when 17
        get_bytes(4, "L")
      when 18
        get_bytes(8, "Q")
      when 20
        get_bytes(4, "f")
      when 21
        get_bytes(8, "d")
      when 30
        count = get_bytes(4, "L")
        get_bytes(count, "a*")
      when 31
        count = get_bytes(4, "L")
        chars = []
        count.times { chars << get_bytes(2, "S") }
        chars.pack("U*")
      when 40
        count = get_bytes(4, "L")
        get_bytes(count, "a*")
      when 41
        Id.new(get_bytes(4, "L"), get_bytes(8, "Q"))
      when 42
        UUIDTools::UUID.parse_raw(get_bytes(16, "a*"))
      when 45
        thread_id = get_bytes(4, "L")
        name = read_impl
        RemoteObject.create_ro(thread_id: thread_id, connection: @connection, name: name)
      when 51
        Time.at(get_bytes(8, "q") / 1e6)
      when 52
        Time.at(get_bytes(8, "q") / 1e6)
      when 60
        count = get_bytes(4, "L")
        count.times.map { read_impl }
      when 61
        count = get_bytes(4, "L")
        Hash[count.times.map { [read_impl, read_impl] }]
      else
        raise "received unsupported type #{type}"
      end
    end

    def send_impl(obj)
      case obj
      when nil
        "\x00"
      when TrueClass, FalseClass
        [1, obj ? 1 : 0].pack("CC")
      when Fixnum
        [13, obj].pack("Cq")
      when Float
        [21, obj].pack("Cd")
      when String, Symbol
        [30, obj.to_s.bytesize, obj.to_s].pack("CLa*")
      when Runivedo::Id
        [41, obj.owner_id, obj.id].pack("CLQ")
      when Array
        [60, obj.count].pack("CL") + obj.map{|e| send_impl(e)}.join
      when Hash
        [61, obj.count].pack("CL") + obj.map{|k, v| send_impl(k) + send_impl(v)}.join
      when UUIDTools::UUID
        [42].pack("C") + obj.raw
      else
        raise "sending not supported for class #{obj.class}"
      end
    end
  end
end
