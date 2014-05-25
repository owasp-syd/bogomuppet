require_relative 'arch'
require_relative 'memory'
require_relative 'register'

class Processor
  attr_reader :mem

  attr_reader :eax, :ax, :al, :ah
  attr_reader :ebx, :bx, :bl, :bh
  attr_reader :ecx, :cx, :cl, :ch
  attr_reader :edx, :dx, :dl, :dh
  def eax=(data) @eax.write(data) end
  def ebx=(data) @ebx.write(data) end
  def ecx=(data) @ecx.write(data) end
  def edx=(data) @edx.write(data) end
  def ax=(data) @ax.write(data) end
  def bx=(data) @bx.write(data) end
  def cx=(data) @cx.write(data) end
  def dx=(data) @dx.write(data) end
  def ah=(data) @ah.write(data) end
  def bh=(data) @bh.write(data) end
  def ch=(data) @ch.write(data) end
  def dh=(data) @dh.write(data) end
  def al=(data) @al.write(data) end
  def bl=(data) @bl.write(data) end
  def cl=(data) @cl.write(data) end
  def dl=(data) @dl.write(data) end

  attr_reader :esi, :edi
  def esi=(data) @esi.write(data) end
  def edi=(data) @edi.write(data) end

  attr_reader :ebp, :esp
  def esp=(data) @esp.write(data) end
  def ebp=(data) @ebp.write(data) end

  attr_reader :eflags
  def eflags=(data) @eflags.write(data) end

  def to_s
    return "#{@esp.addr}: #{@esp.read(1)}"
  end
end

class Intel32 < Processor
  def initialize
    @arch  = IA32.new
    @mem   = Memory.new @arch
    Register.mem = @mem

    @eflags = EFLAGS.new
    @flags  = @eflags[:flags]

    @eip = EIP.new; @ip = @eip[:ip];

    @ebp = EBP.new; @bp = @ebp[:bp]; @ebp.write(0xFFFF0000)
    @esp = ESP.new; @sp = @esp[:sp]; @esp.write(0xFFFF0000)

    @eax = EAX.new; @ax = @eax[:ax]; @al = @eax[:al]; @ah = @eax[:ah]
    @ebx = EBX.new; @bx = @ebx[:bx]; @bl = @ebx[:bl]; @bh = @ebx[:bh]
    @ecx = ECX.new; @cx = @ecx[:cx]; @cl = @ecx[:cl]; @ch = @ecx[:ch]
    @edx = EDX.new; @dx = @edx[:dx]; @dl = @edx[:dl]; @dh = @edx[:dh]

    @esi = ESI.new; @si = @esi[:si]
    @edi = EDI.new; @di = @edi[:di]
  end

  def mov(dst, src)
    if dst.is_a? Register
      case src
        when Register then dst.write(src)
        when Pointer then dst.write(src)
        when Integer then dst.write(src)
        else raise :Jest
      end
    elsif dst.is_a? Pointer
      case src
        when Register then dst.write(src)
        when Integer then dst.write(src)
        when String then dst.write(src)
        else raise :Jest
      end
    end
  end

  def add(dst, src)
    dst += src
  end

  def sub(dst, src)
    dst -= src
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

end

class Intel64 < Processor
  def initialize
    @arch  = IA64.new
    @mem   = Memory.new @arch
    Register.mem = @mem

    @rflags = RFLAGS.new
    @flags  = @rflags[:flags]

    @rip = RIP.new; @eip = @rip[:eip]; @ip = @rip[:ip];

    @rbp = RBP.new; @ebp = @rip[:ebp]; @bp = @rbp[:bp]; @rbp.write(0xFFFFFFFF00000000)
    @rsp = RSP.new; @esp = @rip[:esp]; @sp = @rsp[:sp]; @rsp.write(0xFFFFFFFF00000000)

    @rax = RAX.new; @eap = @rip[:eax]; @ax = @rax[:ax]; @al = @rax[:al]; @ah = @rax[:ah]
    @rbx = RBX.new; @ebp = @rip[:ebx]; @bx = @rbx[:bx]; @bl = @rbx[:bl]; @bh = @rbx[:bh]
    @rcx = RCX.new; @ecp = @rip[:ecx]; @cx = @rcx[:cx]; @cl = @rcx[:cl]; @ch = @rcx[:ch]
    @rdx = RDX.new; @edp = @rip[:edx]; @dx = @rdx[:dx]; @dl = @rdx[:dl]; @dh = @rdx[:dh]

    @rsi = RSI.new; @esp = @rip[:esi]; @si = @rsi[:si]; @sil = @rsi[:sil]
    @rdi = RDI.new; @edp = @rip[:edi]; @si = @rsi[:si]; @dil = @rdi[:dil]

    @r8  = R8.new;  @r8d  = R8D[:r8d];   @r8d  = R8D[:r8w];   @r8d  = R8D[:r8b]
    @r9  = R9.new;  @r9d  = R9D[:r9d];   @r9d  = R9D[:r9w];   @r9d  = R9D[:r9b]
    @r10 = R10.new; @r10d = R10D[:r10d]; @r10d = R10D[:r10w]; @r10d = R10D[:r10b]
    @r11 = R11.new; @r11d = R11D[:r11d]; @r11d = R11D[:r11w]; @r11d = R11D[:r11b]
    @r12 = R12.new; @r12d = R12D[:r12d]; @r12d = R12D[:r12w]; @r12d = R12D[:r12b]
    @r13 = R13.new; @r13d = R13D[:r13d]; @r13d = R13D[:r13w]; @r13d = R13D[:r13b]
    @r14 = R14.new; @r14d = R14D[:r14d]; @r14d = R14D[:r14w]; @r14d = R14D[:r14b]
    @r15 = R15.new; @r15d = R15D[:r15d]; @r15d = R15D[:r15w]; @r15d = R15D[:r15b]
  end
end
