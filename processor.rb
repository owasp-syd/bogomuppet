require_relative 'arch'
require_relative 'memory'
require_relative 'register'

class Processor
  attr_accessor :eax, :ax, :al, :ah
  attr_accessor :ebx, :bx, :bl, :bh
  attr_accessor :ecx, :cx, :cl, :ch
  attr_accessor :edx, :dx, :dl, :dh

  attr_accessor :esi, :edi
  attr_accessor :ebp, :esp

  attr_accessor :mem

  def initialize
    @arch  = IA32.new
    @mem   = Memory.new @arch

    Register.mem   = @mem

    @eflags = EFLAGS.new

    @eip = EIP.new

    @ebp = EBP.new; @ebp.write(0xFFFF0000)
    @esp = ESP.new; @esp.write(0xFFFF0000)

    @eax = EAX.new; @ax = @eax[:ax]; @al = @eax[:al]; @ah = @eax[:ah]
    @ebx = EBX.new; @bx = @ebx[:bx]; @bl = @ebx[:bl]; @bh = @ebx[:bh]
    @ecx = ECX.new; @cx = @ecx[:cx]; @cl = @ecx[:cl]; @ch = @ecx[:ch]
    @edx = EDX.new; @dx = @edx[:dx]; @dl = @edx[:dl]; @dh = @edx[:dh]

    @esi = ESI.new
    @edi = EDI.new
  end

  def eax=(data) @eax.write(data) end
  def ebx=(data) @ebx.write(data) end
  def ecx=(data) @ecx.write(data) end
  def edx=(data) @edx.write(data) end

  def esi=(data) @esi.write(data) end
  def edi=(data) @edi.write(data) end

  def esp=(data) @esp.write(data) end
  def ebp=(data) @ebp.write(data) end

  def mov(dst, src)
    dst.write(src, dst.size)
  end

  def push(data)
    #. The push instruction places its operand onto the top of the hardware
    #. supported stack in memory.
    #.
    #. Specifically, push first decrements ESP by 4, then places its operand
    #. into the contents of the 32-bit location at address [ESP]. ESP (the
    #. stack pointer) is decremented by push since the x86 stack grows down -
    #. i.e. the stack grows from high addresses to lower addresses.
    @esp -= @arch.bytes
    @mem[@esp.read].write(data, @arch.bytes)
  end

  def pop(dst)
    #. The pop instruction removes the 4-byte data element from the top of the
    #. hardware-supported stack into the specified operand (i.e. register or
    #. memory location).
    #.
    #. It first moves the 4 bytes located at memory location [SP] into the
    #. specified register or memory location, and then increments SP by 4.
    dst.write(@esp.read(@arch.bytes))
    @esp += @arch.bytes
  end

  def to_s
    return "#{@esp.addr}: #{@esp.read(1)}"
  end
end
