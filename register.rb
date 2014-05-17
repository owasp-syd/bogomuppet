require_relative 'bitfield'
require_relative 'flag'

#. Intel Registers -={
#. Abstract Intel Register
#. Abstract Register Class -={
class Register
  include Comparable

  @@mem = nil
  def self.mem=(mem)
    @@mem = mem
  end

  @@stack = nil
  def self.stack=(stack)
    @@stack = stack
  end

  def initialize(name, size, bitfield=nil, mask=nil)
    @name = name
    @flags = []

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

  def setflags(fields)
    fields.each do |index, flag|
      if not flag.nil?
        flag.bitfield = self
        @flags[index] = flag
      end
    end
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

  def packed
    return @bitfield.packed(@size)
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

  def [](subregister)
    raise 'Hell'
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
#. }=-

#. Concrete Register Implementations
#. EFLAGS -={
class EFLAGS < Register
  def initialize
    super(:EFLAGS, 0x20)
    @flags = [
      0x00 => Flag.new(0x1, :cf,   :s, 'carry flag'),
      0x02 => Flag.new(0x1, :pf,   :s, 'parity flag'),
      0x04 => Flag.new(0x1, :af,   :s, 'auxiliary carry flag'),
      0x06 => Flag.new(0x1, :zf,   :s, 'zero flag'),
      0x07 => Flag.new(0x1, :sf,   :s, 'sign flag'),
      0x08 => Flag.new(0x1, :tf,   :x, 'trap flag'),
      0x09 => Flag.new(0x1, :if,   :x, 'interrupt enable flag'),
      0x0a => Flag.new(0x1, :df,   :c, 'direction flag'),
      0x0b => Flag.new(0x1, :of,   :s, 'overflow flag'),
      0x0c => Flag.new(0x2, :iopl, :x, 'i/o pivilege level'),
      0x0e => Flag.new(0x1, :nt,   :x, 'nested task'),
      0x10 => Flag.new(0x1, :rf,   :x, 'resume flag'),
      0x11 => Flag.new(0x1, :vm,   :x, 'virtual 8080 mode'),
      0x12 => Flag.new(0x1, :ac,   :x, 'alignment check'),
      0x13 => Flag.new(0x1, :vif,  :x, 'virtual interrupt flag'),
      0x14 => Flag.new(0x1, :vip,  :x, 'virtual interrupt pending'),
      0x15 => Flag.new(0x1, :id,   :x, 'id flag'),
    ]
  end
end
#. }=-

#. General Registers
#. EAX - Accumulator Registers -={
class EAX < Register

  def initialize
    super(:EAX, 0x20)
    @ax      = self.register(:AX, 0xFFFF)
    @al      = self.register(:AL, 0x00FF)
    @ah      = self.register(:AH, 0xFF00)
  end

  def [](subregister)
    case subregister
      when :ax then return @ax
      when :al then return @al
      when :ah then return @ah
      else raise 'Hell'
    end
  end
end
#. }=-
#. EBX - Base Registers -={
class EBX < Register
  def initialize
    super(:EBX, 0x20)
    @bx      = self.register(:BX, 0xFFFF)
    @bl      = self.register(:BL, 0x00FF)
    @bh      = self.register(:BH, 0xFF00)
  end

  def [](subregister)
    case subregister
      when :bx then return @bx
      when :bl then return @bl
      when :bh then return @bh
      else raise 'Hell'
    end
  end
end
#. }=-
#. ECX - Counter Registers -={
class ECX < Register
  def initialize
    super(:ECX, 0x20)
    @cx      = self.register(:CX, 0xFFFF)
    @cl      = self.register(:CL, 0x00FF)
    @ch      = self.register(:CH, 0xFF00)
  end

  def [](subregister)
    case subregister
      when :cx then return @cx
      when :cl then return @cl
      when :ch then return @ch
      else raise 'Hell'
    end
  end
end
#. }=-
#. EDX - Data Registers -={
class EDX < Register
  def initialize
    super(:EDX, 0x20)
    @dx      = self.register(:DX, 0xFFFF)
    @dl      = self.register(:DL, 0x00FF)
    @dh      = self.register(:DH, 0xFF00)
  end

  def [](subregister)
    case subregister
      when :dx then return @dx
      when :dl then return @dl
      when :dh then return @dh
      else raise 'Hell'
    end
  end
end
#. }=-
#. ESI - ??? -={
class ESI < Register
  def initialize
    super(:ESI, 0x20)
  end
end
#. }=-
#. EDI - ??? -={
class EDI < Register
  def initialize
    super(:EDI, 0x20)
  end
end
#. }=-

#. Segment Registers
#. EBP - Base Pointer -={
class EBP < Register
  def initialize
    super(:EBP, 0x20)
  end
end
#. }=-
#. ESP - Stack Pointer -={
class ESP < Register
  def initialize
    super(:ESP, 0x20)
  end
end
#. }=-

#. EIP - Instruction Pointer -={
class EIP < Register
  def initialize
    super(:EIP, 0x20)
  end
end
#. }=-

#. }=-
