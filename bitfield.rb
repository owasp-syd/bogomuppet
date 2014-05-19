class Bitfield
  include Comparable

  def self.mask2size(data)
    count = 0
    while (data != 0)
      data &= (data-1)
      count += 1
    end
    return count
  end

  def initialize(size)
    @data = 0x0
    @size = size
    @fmtstr = "%%0#%dx" % (2 + @size / 4)
  end

  def bit(mode, index)
    return (1 << index)
  end

  def write(mode, data)
    @data = mask(mode)
    @data &= data
  end

  def mask(mode)
    return ((1<<mode)-1)
  end

  def data(mode)
    return @data & mask(mode)
  end

  def packed(mode)
    return [(@data & mode).to_s(16)].pack("H*")
  end

  def to_s
    return @data > 0 ? (@fmtstr.green % @data) : (@fmtstr.red % @data)
  end

  def unset(mode, index)
    @data &= ~bit(mode, index)
  end

  def set(mode, index)
    @data |= bit(mode, index)
  end

  def xor(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data ^= bitfield.data(mode)
    else
      @data ^= bitfield & mask(mode)
    end
    return self
  end

  def and(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data &= bitfield.data(mode)
    else
      @data &= bitfield & mask(mode)
    end
    return self
  end

  def or(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data |= bitfield.data(mode)
    else
      @data |= bitfield & mask(mode)
    end
    return self
  end

  def add(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data += bitfield.data(mode)
    else
      @data += bitfield & mask(mode)
    end
    #@data &= ((1 << mode) - 1)
    return self
  end

  def sub(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data -= bitfield.data(mode)
    else
      @data -= bitfield & mask(mode)
    end
    #@data &= ((1 << mode) - 1)
    return self
  end

  def mul(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data *= bitfield.data(mode)
    else
      @data *= bitfield & mask(mode)
    end
    #@data &= ((1 << mode) - 1)
    return self
  end

  def div(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data /= bitfield.data(mode)
    else
      @data /= bitfield & mask(mode)
    end
    #@data &= ((1 << mode) - 1)
    return self
  end

  def inc(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data += bitfield.data(mode)
    else
      @data += bitfield & mask(mode)
    end
    #@data &= ((1 << mode) - 1)
    return self
  end

  def dec(mode, bitfield)
    if bitfield.is_a? Bitfield
      @data -= bitfield.data(mode)
    else
      @data -= bitfield & mask(mode)
    end
    #@data &= ((1 << mode) - 1)
    return self
  end
end
