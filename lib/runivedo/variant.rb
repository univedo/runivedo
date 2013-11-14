require "bigdecimal"

module Runivedo
  module VariantMajor
    UINT = 0
    NEGINT = 1
    BYTESTRING = 2
    TEXTSTRING = 3
    ARRAY = 4
    MAP = 5
    TAG = 6
    FLOAT = 7
  end

  module VariantTag
    DECIMAL = 4
    REMOTEOBJECT = 6
    UUID = 7
    TIME = 8
    DATETIME = 9
    SQL = 10
  end

  module VariantSimple
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
      when VariantMajor::UINT
        get_len(typeInt)
      when VariantMajor::NEGINT
        -get_len(typeInt)-1
      when VariantMajor::BYTESTRING
        count = get_len(typeInt)
        get_bytes(count, "a*")
      when VariantMajor::TEXTSTRING
        count = get_len(typeInt)
        s = get_bytes(count, "a*").force_encoding(Encoding::UTF_8)
        raise "received non-utf8 string when expecting utf8" unless s.valid_encoding?
        s
      when VariantMajor::ARRAY
        count = get_len(typeInt)
        count.times.map { read_impl }
      when VariantMajor::MAP
        count = get_len(typeInt)
        Hash[count.times.map { [read_impl, read_impl] }]
      when VariantMajor::TAG
        tag = get_len(typeInt)
        case tag
        when VariantTag::DECIMAL
          arr = read_impl
          raise "inconsistent type" if arr.length != 2
          BigDecimal.new(arr[0]) * (10 ** arr[1])
        when VariantTag::REMOTEOBJECT
          arr = read_impl
          raise "inconsistent type" if arr.length != 2
          RemoteObject.create_ro(thread_id: arr[0], connection: @connection, name: arr[1])
        when VariantTag::UUID
          UUIDTools::UUID.parse_raw(read_impl)
        when VariantTag::TIME, VariantTag::DATETIME
          Time.at(read_impl.to_r / 1000000)
        else
          raise "Tag not supported"
        end
      when VariantMajor::FLOAT
        case typeInt & 0x1F
        when VariantSimple::FALSE
          false
        when VariantSimple::TRUE
          true
        when VariantSimple::NULL
          nil
        when VariantSimple::FLOAT16
          raise "half precision float not supported"
        when VariantSimple::FLOAT32
          get_bytes(4, "f")
        when VariantSimple::FLOAT64
          get_bytes(8, "d")
        else
          raise "invalid simple"
        end
      else
        raise "unknown major"
      end
    end

    def send_simple(val)
      [(VariantMajor::FLOAT << 5) | val].pack("C")
    end

    def send_tag(tag)
      [(VariantMajor::TAG << 5) | tag].pack("C")
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
      else
        [typeInt | 27, len].pack("CQ>")
      end
    end

    def send_impl(obj)
      case obj
      when nil
        send_simple(VariantSimple::NULL)
      when TrueClass
        send_simple(VariantSimple::TRUE)
      when FalseClass
        send_simple(VariantSimple::FALSE)
      when Fixnum, Bignum
        if obj < 0
          send_len(VariantMajor::NEGINT, -obj-1)
        else
          send_len(VariantMajor::UINT, obj)
        end
      when Float
        send_simple(VariantSimple::FLOAT64) + [obj].pack("d")
      when String, Symbol
        s = obj.to_s.dup.force_encoding(Encoding::UTF_8)
        send_len(s.valid_encoding? ? VariantMajor::TEXTSTRING : VariantMajor::BYTESTRING, s.bytesize) + s.b
      when Symbol
        send_impl(obj.to_s.force_encoding(Encoding::UTF_8))
      when Time
        send_tag(VariantTag::TIME) + send_impl((obj.to_r*1000000).to_i)
      when Array
        send_len(VariantMajor::ARRAY, obj.count) + obj.map{|e| send_impl(e)}.join
      when Hash
        send_len(VariantMajor::MAP, obj.count) + obj.map{|k, v| send_impl(k.to_s) + send_impl(v)}.join
      when UUIDTools::UUID
        send_tag(VariantTag::UUID) + send_impl(obj.raw.b)
      else
        raise "sending not supported for class #{obj.class}"
      end
    end
  end
end
