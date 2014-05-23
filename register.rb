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
#. FLAGS Register -={
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
#. AX - 16/32/64 Accumulator Registers -={
class RAX < Register
  def initialize
    super(:RAX, 0x40)
    @eax = self.register(:EAX, 0xFFFFFFFF)
    @ax  = self.register( :AX, 0x0000FFFF)
    @al  = self.register( :AL, 0x000000FF)
    @ah  = self.register( :AH, 0x0000FF00)
  end

  def [](subregister)
    case subregister
      when :eax then return @eax
      when  :ax then return @ax
      when  :al then return @al
      when  :ah then return @ah
      else raise 'Hell'
    end
  end
end

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
#. BX - 16/32/64 Base Registers -={
class RBX < Register
  def initialize
    super(:RBX, 0x40)
    @ebx = self.register(:EBX, 0xFFFFFFFF)
    @bx  = self.register( :BX, 0x0000FFFF)
    @bl  = self.register( :BL, 0x000000FF)
    @bh  = self.register( :BH, 0x0000FF00)
  end

  def [](subregister)
    case subregister
      when :ebx then return @ebx
      when  :bx then return @bx
      when  :bl then return @bl
      when  :bh then return @bh
      else raise 'Hell'
    end
  end
end

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
#. CX - 16/32/64 Counter Registers -={
class RCX < Register
  def initiclize
    super(:RCX, 0x40)
    @ecx = self.register(:ECX, 0xFFFFFFFF)
    @cx  = self.register( :CX, 0x0000FFFF)
    @cl  = self.register( :CL, 0x000000FF)
    @ch  = self.register( :CH, 0x0000FF00)
  end

  def [](subregister)
    case subregister
      when :ecx then return @ecx
      when  :cx then return @cx
      when  :cl then return @cl
      when  :ch then return @ch
      else raise 'Hell'
    end
  end
end

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
#. DX - 16/32/64 Data Registers -={
class RDX < Register
  def initidlize
    super(:RDX, 0x40)
    @edx = self.register(:EDX, 0xFFFFFFFF)
    @dx  = self.register( :DX, 0x0000FFFF)
    @dl  = self.register( :DL, 0x000000FF)
    @dh  = self.register( :DH, 0x0000FF00)
  end

  def [](subregister)
    case subregister
      when :edx then return @edx
      when  :dx then return @dx
      when  :dl then return @dl
      when  :dh then return @dh
      else raise 'Hell'
    end
  end
end

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
#. SI - 16/32/64 Source Index -={
class RSI < Register
  def initialize
    super(:RSI, 0x40)
    @esi = self.register(:ESI,  0xFFFFFFFF)
    @si  = self.register( :SI,  0x0000FFFF)
    @sil = self.register( :SIL, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :esi then return @esi
      when  :si then return @si
      when :sil then return @si;
      else raise 'Hell'
    end
  end
end

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
#. DI - 16/32/64 Destination Index -={
class RDI < Register
  def initialize
    super(:RDI, 0x40)
    @edi = self.register(:EDI,  0xFFFFFFFF)
    @di  = self.register( :DI,  0x0000FFFF)
    @dil = self.register( :DIL, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :edi then return @edi
      when  :di then return @di
      when :dil then return @dil
      else raise 'Hell'
    end
  end
end

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

#. Pointer Registers
#. BP - 16/32/64 Base Pointer -={
class RBP < Register
  def initialize
    super(:RBP, 0x40)
    @ebp = self.register(:EBP, 0xFFFFFFFF)
    @bp  = self.register( :BP, 0x0000FFFF)
  end

  def [](subregister)
    case subregister
      when :ebp then return @ebp
      when  :bp then return @bp
      else raise 'Hell'
    end
  end
end

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
#. SP - 16/32/64 Stack Pointer -={
class RSP < Register
  def initialize
    super(:RSP, 0x40)
    @esp = self.register(:ESP, 0xFFFFFFFF)
    @sp  = self.register( :SP, 0x0000FFFF)
  end

  def [](subregister)
    case subregister
      when :esp then return @esp
      when  :sp then return @sp
      else raise 'Hell'
    end
  end
end

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
#. IP - 16/32/64 Instruction Pointer -={
class RIP < Register
  def initialize
    super(:RIP, 0x40)
    @eip = self.register(:EIP, 0xFFFFFFFF)
    @ip  = self.register( :IP, 0x0000FFFF)
  end

  def [](subregister)
    case subregister
      when :eip then return @eip
      when  :ip then return @ip
      else raise 'Hell'
    end
  end
end

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

#. Segment Registers
#. CS - 16/32/64 Code Segment Register -={
class CS < Register
  def initialize
    super(:CS, 0x10)
  end
end
#. }=-
#. DS - 16/32/   Data Segment Register -={
class DS < Register
  def initialize
    super(:DS, 0x10)
  end
end
#. }=-
#. SS - 16/32/   Stack Segment Register -={
class SS < Register
  def initialize
    super(:SS, 0x10)
  end
end
#. }=-
#. ES - 16/32/   Extra Segment Register -={
class ES < Register
  def initialize
    super(:ES, 0x10)
  end
end
#. }=-
#. FS -   /32/64 80386 PIII only -={
class FS < Register
  def initialize
    super(:FS, 0x10)
  end
end
#. }=-
#. GS -   /32/64 80386 PIII only -={
class GS < Register
  def initialize
    super(:GS, 0x10)
  end
end
#. }=-

#. x86_64 Registers
#. R8  -  /  /64 Register -={
class R8 < Register
  def initialize
    super(:R8, 0x40)
    @r8d = self.register(:R8D, 0xFFFFFFFF)
    @r8w = self.register(:R8W, 0x0000FFFF)
    @r8b = self.register(:R8B, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :r8d then return @r8d
      when :r8w then return @r8w
      when :r8b then return @r8b
      else raise 'Hell'
    end
  end
end
#. }=-
#. R9  -  /  /64 Register -={
class R9 < Register
  def initialize
    super(:R9, 0x40)
    @r9d = self.register(:R9D, 0xFFFFFFFF)
    @r9w = self.register(:R9W, 0x0000FFFF)
    @r9b = self.register(:R9B, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :r9d then return @r9d
      when :r9w then return @r9w
      when :r9b then return @r9b
      else raise 'Hell'
    end
  end
end
#. }=-
#. R10 -  /  /64 Register -={
class R10 < Register
  def initialize
    super(:R10, 0x40)
    @r10d = self.register(:R10D, 0xFFFFFFFF)
    @r10w = self.register(:R10W, 0x0000FFFF)
    @r10b = self.register(:R10B, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :r10d then return @r10d
      when :r10w then return @r10w
      when :r10b then return @r10b
      else raise 'Hell'
    end
  end
end
#. }=-
#. R11 -  /  /64 Register -={
class R11 < Register
  def initialize
    super(:R11, 0x40)
    @r11d = self.register(:R11D, 0xFFFFFFFF)
    @r11w = self.register(:R11W, 0x0000FFFF)
    @r11b = self.register(:R11B, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :r11d then return @r11d
      when :r11w then return @r11w
      when :r11b then return @r11b
      else raise 'Hell'
    end
  end
end
#. }=-
#. R12 -  /  /64 Register -={
class R12 < Register
  def initialize
    super(:R12, 0x40)
    @r12d = self.register(:R12D, 0xFFFFFFFF)
    @r12w = self.register(:R12W, 0x0000FFFF)
    @r12b = self.register(:R12B, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :r12d then return @r12d
      when :r12w then return @r12w
      when :r12b then return @r12b
      else raise 'Hell'
    end
  end
end
#. }=-
#. R13 -  /  /64 Register -={
class R13 < Register
  def initialize
    super(:R13, 0x40)
    @r13d = self.register(:R13D, 0xFFFFFFFF)
    @r13w = self.register(:R13W, 0x0000FFFF)
    @r13b = self.register(:R13B, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :r13d then return @r13d
      when :r13w then return @r13w
      when :r13b then return @r13b
      else raise 'Hell'
    end
  end
end
#. }=-
#. R14 -  /  /64 Register -={
class R14 < Register
  def initialize
    super(:R14, 0x40)
    @r14d = self.register(:R14D, 0xFFFFFFFF)
    @r14w = self.register(:R14W, 0x0000FFFF)
    @r14b = self.register(:R14B, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :r14d then return @r14d
      when :r14w then return @r14w
      when :r14b then return @r14b
      else raise 'Hell'
    end
  end
end
#. }=-
#. R15 -  /  /64 Register -={
class R15 < Register
  def initialize
    super(:R15, 0x40)
    @r15d = self.register(:R15D, 0xFFFFFFFF)
    @r15w = self.register(:R15W, 0x0000FFFF)
    @r15b = self.register(:R15B, 0x000000FF)
  end

  def [](subregister)
    case subregister
      when :r15d then return @r15d
      when :r15w then return @r15w
      when :r15b then return @r15b
      else raise 'Hell'
    end
  end
end
#. }=-

#. MMX - TODO
#. SSE - TODO
#. }=-
