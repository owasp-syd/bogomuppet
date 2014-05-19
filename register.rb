require 'colorize'
require 'pp'

require_relative 'bitfield'
require_relative 'flag'

#. Intel Registers -={
#. Abstract Intel Register
#. Abstract Register Class -={
class Register
  include Comparable

  attr_reader :size

  class << self
    @@mem = nil
    def mem=(mem)
      @@mem = mem
    end

    @@stack = nil
    def stack=(stack)
      @@stack = stack
    end
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
      @size = mask_width mask
    end
  end

  def register(name, mask)
    return Register.new(name, -1, @bitfield, mask)
  end

  def read(size=nil)
    #. Return the immediate value in the register is no size specified
    #.
    #. If a size is specified, then assume the register contains an address,
    #. dereference to that address and read size bytes from there

    if size.nil?
      return @bitfield.data(@size)
    else
      return @@mem[@bitfield.data(@size)].read(size)
    end
  end

  def packed
    return @bitfield.packed(@size)
  end

  def write(data, junk=nil)
    case data
      when Integer
        @bitfield.write(@size, data)
      when String
        @bitfield.write(@size, data[0...@@mem.arch.bytes].unpack('V*').pop)
      when Pointer
        @bitfield.write(@size, data.addr)
      when Register
        @bitfield.write(@size, data.read)
      else
        raise "Junk: #{data}"
    end
  end

  def bitfield
    return @bitfield
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

  def -(object)
    if object.is_a? Register
      @bitfield = @bitfield.sub(@size, object.bitfield)
    else
      @bitfield = @bitfield.sub(@size, object)
    end

    return self
  end

  def +(object)
    if object.is_a? Register
      @bitfield = @bitfield.add(@size, object.bitfield)
    else
      @bitfield = @bitfield.add(@size, object)
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
    if self.read < reg.read
      return -1
    elsif self.read > reg.read
      return 1
    else
      return 0
    end
  end

  def [](subregister)
    raise 'Hell'
  end

  def to_s
    s = nil

    if @flags.count > 0
      s = sprintf("%s[%s]", @name.to_s, @flags.map { |flag| flag.to_s }.join)
    else
      s = sprintf("%s[%s]", @name.to_s, @bitfield.to_s)
    end

    return s
  end
end
#. }=-

#. Concrete Register Implementations
#. EFLAGS -={
class EFLAGS < Register
  def initialize
    super(:EFLAGS, 0x20)
    @flags = [
      Flag.new(self, 0x00000001, :cf,   :s, 'carry flag'),
      Flag.new(self, 0x00000004, :pf,   :s, 'parity flag'),
      Flag.new(self, 0x00000010, :af,   :s, 'auxiliary carry flag'),
      Flag.new(self, 0x00000040, :zf,   :s, 'zero flag'),
      Flag.new(self, 0x00000080, :sf,   :s, 'sign flag'),
      Flag.new(self, 0x00000100, :tf,   :x, 'trap flag'),
      Flag.new(self, 0x00000200, :if,   :x, 'interrupt enable flag'),
      Flag.new(self, 0x00000400, :df,   :c, 'direction flag'),
      Flag.new(self, 0x00000800, :of,   :s, 'overflow flag'),
      Flag.new(self, 0x00003000, :iopl, :x, 'i/o pivilege level'),
      Flag.new(self, 0x00004000, :nt,   :x, 'nested task'),
      Flag.new(self, 0x00010000, :rf,   :x, 'resume flag'),
      Flag.new(self, 0x00020000, :vm,   :x, 'virtual 8080 mode'),
      Flag.new(self, 0x00040000, :ac,   :x, 'alignment check'),
      Flag.new(self, 0x00080000, :vif,  :x, 'virtual interrupt flag'),
      Flag.new(self, 0x00100000, :vip,  :x, 'virtual interrupt pending'),
      Flag.new(self, 0x00200000, :id,   :x, 'id flag'),
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
