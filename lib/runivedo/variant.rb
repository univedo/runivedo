require "bigdecimal"

module Runivedo
  module CborMajor
    UINT = 0
    NEGINT = 1
    BYTESTRING = 2
    TEXTSTRING = 3
    ARRAY = 4
    MAP = 5
    TAG = 6
    FLOAT = 7
  end

  module CborTag
    DATETIME = 0
    TIME = 1
    DECIMAL = 4
    REMOTEOBJECT = 6
    UUID = 7
    RECORD = 8
  end

  module CborSimple
    FALSE = 20
    TRUE = 21
    NULL = 22
    FLOAT16 = 25
    FLOAT32 = 26
    FLOAT64 = 27
  end

  module Variant
    private
    def get_len(typeInt)
      smallLen = typeInt & 0x1F
      case smallLen
      when 24
        get_bytes(1, "C")
      when 25
        get_bytes(2, "S>")
      when 26
        get_bytes(4, "L>")
      when 27
        get_bytes(8, "Q>")
      else
        smallLen
      end
    end

    def read_impl
      typeInt = get_bytes(1, "C")
      major = (typeInt >> 5)

      case major
      when CborMajor::UINT
        get_len(typeInt)
      when CborMajor::NEGINT
        -get_len(typeInt)-1
      when CborMajor::BYTESTRING
        count = get_len(typeInt)
        get_bytes(count, "a*")
      when CborMajor::TEXTSTRING
        count = get_len(typeInt)
        s = get_bytes(count, "a*").force_encoding(Encoding::UTF_8)
        raise "received non-utf8 string when expecting utf8" unless s.valid_encoding?
        s
      when CborMajor::ARRAY
        count = get_len(typeInt)
        count.times.map { read_impl }
      when CborMajor::MAP
        count = get_len(typeInt)
        Hash[count.times.map { [read_impl, read_impl] }]
      when CborMajor::TAG
        tag = get_len(typeInt)
        case tag
        when CborTag::DECIMAL
          arr = read_impl
          raise "invalid decimal" if arr.length != 2
          BigDecimal.new(arr[1]) * (BigDecimal.new(10) ** arr[0])
        when CborTag::REMOTEOBJECT
          arr = read_impl
          raise "invalid remoteobject" if arr.length != 2
          RemoteObject.create_ro(thread_id: arr[0], connection: @connection, name: arr[1])
        when CborTag::UUID
          UUIDTools::UUID.parse_raw(read_impl)
        when CborTag::DATETIME
          Time.iso8601(read_impl)
        when CborTag::TIME
          Time.at(read_impl)
        when CborTag::RECORD
          read_impl
        else
          raise "Tag not supported"
        end
      when CborMajor::FLOAT
        case typeInt & 0x1F
        when CborSimple::FALSE
          false
        when CborSimple::TRUE
          true
        when CborSimple::NULL
          nil
        when CborSimple::FLOAT16
          raise "half precision float not supported"
        when CborSimple::FLOAT32
          get_bytes(4, "g")
        when CborSimple::FLOAT64
          get_bytes(8, "G")
        else
          raise "invalid simple"
        end
      else
        raise "unknown major"
      end
    end

    def send_simple(val)
      [(CborMajor::FLOAT << 5) | val].pack("C")
    end

    def send_tag(tag)
      [(CborMajor::TAG << 5) | tag].pack("C")
    end

    def send_len(major, len)
      typeInt = (major << 5);
      if len <= 23
        [typeInt | len].pack("C")
      elsif len < 0x100
        [typeInt | 24, len].pack("CC")
      elsif len < 0x10000
        [typeInt | 25, len].pack("CS>")
      elsif len < 0x100000000
        [typeInt | 26, len].pack("CL>")
      elsif len < 0x10000000000000000
        [typeInt | 27, len].pack("CQ>")
      else
        raise "can only send 64bit integers"
      end
    end

    def send_impl(obj)
      case obj
      when nil
        send_simple(CborSimple::NULL)
      when TrueClass
        send_simple(CborSimple::TRUE)
      when FalseClass
        send_simple(CborSimple::FALSE)
      when BigDecimal
        sign, significant_digits, base, exponent = obj.split
        raise "NaN while sending BigDecimal" if sign == 0
        val = sign * significant_digits.to_i(base)
        send_tag(CborTag::DECIMAL) + send_impl([exponent - significant_digits.size, val])
      when Fixnum, Bignum
        if obj < 0
          send_len(CborMajor::NEGINT, -obj-1)
        else
          send_len(CborMajor::UINT, obj)
        end
      when Float
        send_simple(CborSimple::FLOAT64) + [obj].pack("G")
      when String, Symbol
        s = obj.to_s.dup.force_encoding(Encoding::UTF_8)
        send_len(s.valid_encoding? ? CborMajor::TEXTSTRING : CborMajor::BYTESTRING, s.bytesize) + s.b
      when Time
        send_tag(CborTag::DATETIME) + send_impl(obj.iso8601(6))
      when Array
        send_len(CborMajor::ARRAY, obj.count) + obj.map{|e| send_impl(e)}.join
      when Hash
        send_len(CborMajor::MAP, obj.count) + obj.map{|k, v| send_impl(k.to_s) + send_impl(v)}.join
      when UUIDTools::UUID
        "\xc7\x50".b + obj.raw.b
      else
        raise "sending not supported for class #{obj.class}"
      end
    end
  end
end
