require_relative 'util'

class Bitfield
  include Comparable

  def initialize(size)
    @data = 0x0
    @size = size
    @mask = (1 << @size) - 1
    @fmtstr = "%%0#%dx" % (2 + @size / 4)
  end

  def to_s
    return @data > 0 ? (@fmtstr.green % @data) : (@fmtstr.red % @data)
  end

  def bit(index)
    return (1 << index)
  end

  def bit_unset(mask, index)
    @data &= ~bit(index) << mask_lshift_width(mask)
  end

  def bit_set(mask, index)
    @data |= bit(index) << mask_lshift_width(mask)
  end

  def write(data, mask)
    data <<= mask_lshift_width(mask)
    @data &= (@mask ^ mask)
    @data |= (data & mask)
  end

  def data(mask)
    return (@data & mask) >> mask_lshift_width(mask)
  end

  def packed(mask)
    return [self.data(mask).to_s(16)].pack("H*")
  end

  def op(op, mask, operand)
    val = nil
    case operand
      when Bitfield then val = operand.data(mask)
      when Integer then val = operand
      else raise 'Hell'
    end

    def operate(operator, v1, v2)
      v3 = nil
      case operator
        when :xor then v3 = v2 ^ v1
        when :or  then v3 = v2 | v1
        when :and then v3 = v2 & v1
        when :add then v3 = v2 + v1
        when :sub then v3 = v2 - v1
        when :mul then v3 = v2 * v1
        when :div then v3 = v2 / v1
      end
      return v3
    end

    shift = mask_lshift_width(mask)
    @data = (
      @data & (@mask ^ mask)
    ) | (
      mask & ( operate(op, val, data(mask)) ) << shift
    )

    return self
  end

  def xor(mask, operand) return op(:xor, mask, operand) end
  def  or(mask, operand) return op(:or , mask, operand) end
  def and(mask, operand) return op(:and, mask, operand) end
  def add(mask, operand) return op(:add, mask, operand) end
  def sub(mask, operand) return op(:sub, mask, operand) end
  def mul(mask, operand) return op(:mul, mask, operand) end
  def div(mask, operand) return op(:div, mask, operand) end
end
