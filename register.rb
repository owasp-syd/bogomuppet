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

  #. Either set size, or bitfield and mask to initialize a Register
  def initialize(name, size, bitfield=nil, mask=nil)
    @name = name
    @mask = mask

    if size > 0
      @size = size
      @mask = (1 << size) - 1
      @bitfield = Bitfield.new @size
    else
      @bitfield = bitfield
      @size = mask_width @mask
    end

    @flags = []
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
      return @bitfield.data(@mask)
    else
      return @@mem[@bitfield.data(@mask)].read(size)
    end
  end

  def packed
    return @bitfield.packed(@mask)
  end

  def write(data, junk=nil)
    case data
      when Integer
        @bitfield.write(@mask, data)
      when String
        @bitfield.write(@mask, data[0...@@mem.arch.bytes].unpack('V*').pop)
      when Pointer
        @bitfield.write(@mask, data.addr)
      when Register
        @bitfield.write(@mask, data.read)
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
      @bitfield = @bitfield.xor(@mask, object.bitfield)
    else
      @bitfield = @bitfield.xor(@mask, object)
    end

    return self
  end

  def *(object)
    if object.is_a? Register
      @bitfield = @bitfield.mul(@mask, object.bitfield)
    else
      @bitfield = @bitfield.mul(@mask, object)
    end

    return self
  end

  def /(object)
    if object.is_a? Register
      @bitfield = @bitfield.div(@mask, object.bitfield)
    else
      @bitfield = @bitfield.div(@mask, object)
    end

    return self
  end

  def -(object)
    if object.is_a? Register
      @bitfield = @bitfield.sub(@mask, object.bitfield)
    else
      @bitfield = @bitfield.sub(@mask, object)
    end

    return self
  end

  def +(object)
    if object.is_a? Register
      @bitfield = @bitfield.add(@mask, object.bitfield)
    else
      @bitfield = @bitfield.add(@mask, object)
    end

    return self
  end

  def &(object)
    if object.is_a? Register
      @bitfield = @bitfield.and(@mask, object.bitfield)
    else
      @bitfield = @bitfield.and(@mask, object)
    end

    return self
  end

  def |(object)
    if object.is_a? Register
      @bitfield = @bitfield.or(@mask, object.bitfield)
    else
      @bitfield = @bitfield.or(@mask, object)
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
      s = sprintf("%s[%s]", @name.to_s.yellow, (@flags.map { |flag| flag.to_s }.join))
    else
      s = sprintf("%s[%s]", @name.to_s.yellow, "%0##{@size/16}x".green % self.read)
    end

    return s
  end
end
#. }=-

#. Concrete Register Implementations
#. FLAGS -={
class EFLAGS < Register
  def initialize
    super(:EFLAGS, 0x20)
    @flags = [
      Flag.new(self, 0x00000001, :cf,   :status,  'carry flag'),
      Flag.new(self, 0x00000004, :pf,   :status,  'parity flag'),
      Flag.new(self, 0x00000010, :af,   :status,  'auxiliary carry flag'),
      Flag.new(self, 0x00000040, :zf,   :status,  'zero flag'),
      Flag.new(self, 0x00000080, :sf,   :status,  'sign flag'),
      Flag.new(self, 0x00000100, :tf,   :system,  'trap flag'),
      Flag.new(self, 0x00000200, :if,   :system,  'interrupt enable flag'),
      Flag.new(self, 0x00000400, :df,   :control, 'direction flag'),
      Flag.new(self, 0x00000800, :of,   :status,  'overflow flag'),
      Flag.new(self, 0x00003000, :iopl, :system,  'i/o pivilege level'),
      Flag.new(self, 0x00004000, :nt,   :system,  'nested task'),
      Flag.new(self, 0x00010000, :rf,   :system,  'resume flag'),
      Flag.new(self, 0x00020000, :vm,   :system,  'virtual 8080 mode'),
      Flag.new(self, 0x00040000, :ac,   :system,  'alignment check'),
      Flag.new(self, 0x00080000, :vif,  :system,  'virtual interrupt flag'),
      Flag.new(self, 0x00100000, :vip,  :system,  'virtual interrupt pending'),
      Flag.new(self, 0x00200000, :id,   :system,  'id flag'),
    ]
    write(0x2)

    @_flags = self.register(:FLAGS, 0xFFFF)
  end

  def [](subregister)
    case subregister
      when :flags then return @_flags
      else raise 'Hell'
    end
  end
end
#. }=-

#. General Registers
#. AX - Accumulator Registers -={
class EAX < Register
  def initialize
    super(:EAX, 0x20)
    @ax = self.register(:AX, 0xFFFF)
    @al = self.register(:AL, 0x00FF)
    @ah = self.register(:AH, 0xFF00)
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
#. BX - Base Registers -={
class EBX < Register
  def initialize
    super(:EBX, 0x20)
    @bx = self.register(:BX, 0xFFFF)
    @bl = self.register(:BL, 0x00FF)
    @bh = self.register(:BH, 0xFF00)
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
#. CX - Counter Registers -={
class ECX < Register
  def initialize
    super(:ECX, 0x20)
    @cx = self.register(:CX, 0xFFFF)
    @cl = self.register(:CL, 0x00FF)
    @ch = self.register(:CH, 0xFF00)
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
#. DX - Data Registers -={
class EDX < Register
  def initialize
    super(:EDX, 0x20)
    @dx = self.register(:DX, 0xFFFF)
    @dl = self.register(:DL, 0x00FF)
    @dh = self.register(:DH, 0xFF00)
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

#. General & String Manipulation Registers
#. SI - Source Index -={
class ESI < Register
  def initialize
    super(:ESI, 0x20)
    @si = self.register(:SI, 0xFFFF)
  end

  def [](subregister)
    case subregister
      when :si then return @si
      else raise 'Hell'
    end
  end
end
#. }=-
#. DI - Destination Index -={
class EDI < Register
  def initialize
    super(:EDI, 0x20)
    @di = self.register(:DI, 0xFFFF)
  end

  def [](subregister)
    case subregister
      when :di then return @di
      else raise 'Hell'
    end
  end
end
#. }=-

#. Segment Registers
#. CS - Code Segment Register -={
class CS < Register
  def initialize
    super(:CS, 0x10)
  end
end
#. }=-
#. DS - Data Segment Register -={
class DS < Register
  def initialize
    super(:DS, 0x10)
  end
end
#. }=-
#. SS - Stack Segment Register -={
class SS < Register
  def initialize
    super(:SS, 0x10)
  end
end
#. }=-
#. ES - Extra Segment Register -={
class ES < Register
  def initialize
    super(:ES, 0x10)
  end
end
#. }=-
#. FS - 80386 PIII only - TODO
#. GS - 80386 PIII only - TODO

#. Pointer Registers
#. BP - Base Pointer -={
class EBP < Register
  def initialize
    super(:EBP, 0x20)
    @bp = self.register(:BP, 0xFFFF)
  end

  def [](subregister)
    case subregister
      when :bp then return @bp
      else raise 'Hell'
    end
  end
end
#. }=-
#. SP - Stack Pointer -={
class ESP < Register
  def initialize
    super(:ESP, 0x20)
    @sp = self.register(:SP, 0xFFFF)
  end

  def [](subregister)
    case subregister
      when :sp then return @sp
      else raise 'Hell'
    end
  end
end
#. }=-
#. IP - Instruction Pointer -={
class EIP < Register
  def initialize
    super(:EIP, 0x20)
    @ip = self.register(:IP, 0xFFFF)
  end

  def [](subregister)
    case subregister
      when :ip then return @ip
      else raise 'Hell'
    end
  end
end
#. }=-
#. }=-
