require_relative 'bitfield'

class Register
  include Comparable

  @@mem = nil

  def self.mem=(mem)
    @@mem = mem
  end

  def initialize(name, size, bitfield=nil, mask=nil)
    @name = name

    #. Either set size, or bitfield and mask
    if size > 0
      @size = size
      @bitfield = Bitfield.new @size
    else
      @bitfield = bitfield
      @size = Bitfield.mask2size mask
    end

    @fmtstr = "%%0#%dx" % (2 + @size / 4)
  end

  def register(name, mask)
    return Register.new(name, -1, @bitfield, mask)
  end

  def write(data)
    if data.is_a? Integer
      @bitfield.write(@size, data)
    elsif data.is_a? Pointer
      @bitfield.write(@size, data.addr)
    elsif data.is_a? Register
      @bitfield.write(@size, data.bits)
    else
      raise "Hell", data
    end
  end

  def bitfield
    return @bitfield
  end

  def bits
    return @bitfield.data(@size)
  end

  def [](index)
    if 0 <= index < @size
      return @bitfield[index]
    else
      raise 'Hell'
    end
  end

  def []=(index, boolean)
    if 0 <= index < @size and [0, 1].include? index
      @bitfield[index] = boolean
    else
      raise 'Hell'
    end
  end

  def ^(object)
    if object.is_a? Register
      @bitfield = @bitfield.xor(@size, object.bitfield)
    else
      @bitfield = @bitfield.xor(@size, object)
    end

    return self
  end

  def *(object)
    if object.is_a? Register
      @bitfield = @bitfield.mul(@size, object.bitfield)
    else
      @bitfield = @bitfield.mul(@size, object)
    end

    return self
  end

  def /(object)
    if object.is_a? Register
      @bitfield = @bitfield.div(@size, object.bitfield)
    else
      @bitfield = @bitfield.div(@size, object)
    end

    return self
  end

  def &(object)
    if object.is_a? Register
      @bitfield = @bitfield.and(@size, object.bitfield)
    else
      @bitfield = @bitfield.and(@size, object)
    end

    return self
  end

  def |(object)
    if object.is_a? Register
      @bitfield = @bitfield.or(@size, object.bitfield)
    else
      @bitfield = @bitfield.or(@size, object)
    end

    return self
  end

  def <=>(reg)
    if self.bits < reg.bits
      return -1
    elsif self.bits > reg.bits
      return 1
    else
      return 0
    end
  end


  def dec() return self.-(1) end
  def -(int)
    @bitfield.dec(@size, int)
    return self
  end

  def inc() return self.+(1) end
  def +(int)
    @bitfield.inc(@size, int)
    return self
  end

  def to_s
    return "%3s:" % @name.to_s + sprintf(@fmtstr, @bitfield.data(@size))
  end
end
