require_relative 'arch'
require_relative 'memory'
require_relative 'register'
require_relative 'idt'

class Processor
  @@IDT = 0
  @@IDTLength = 255

  attr_reader :mem
  attr_reader :eip, :ip

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

  def autosetflags(reg)
    # Carry     - done, in each arithmetic option using originaldst
    # Parity    - done, autosetflags
    # Adjust    - done, see carry
    # Zero      - done, autosetflags
    # Sign      - done, check 'add' for size-agnostic method
    # Direction - done
    # Overflow  - todo

    if reg.is_a? Register
      parity = 0
      resultlsb = reg.bitfield.data(0x000000FF)
      for i in resultlsb.to_s(2).split('') do
        parity += 1 if i == '1'
      end

      #. If the number of bits in the LSB is even, set the parity flag
      set_pf((parity % 2) == 0)

      #. If the register equates to zero, set the zero flag
      set_zf(reg == 0)

    else
      raise 'Only call Processor#autosetflags with a Register'
    end
  end

  def mov(dst, src)
    if dst.is_a? Register
      case src
        when Register then dst.write(src)
        when Pointer then dst.write(src)
        when Integer then dst.write(src)
        else raise :Jest
      end
      autosetflags(dst)
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
    originaldst = dst
    dst += src
    # If(dst + src > 2 ** dst.size then set_cf(true) else set_cf(false) end
    set_cf(dst < originaldst)

    # Sign field = lowest nibble
    set_af(dst.bitfield.data(0xF) < originaldst.bitfield.data(0xF))

    # Set if most significant bit is set
    set_sf(dst.bitfield.data(2 ** (dst.size - 1)) > 0)

    # When you add two numbers and set a carry flag, the overflow flag must be 1
    # (add is unsigned)
    set_of(dst < originaldst)

    autosetflags(dst)

    return dst
  end

  def sub(dst, src)
    dst -= src

    autosetflags(dst)

    return dst
  end

  def and(dst, src)
    dst &= src
  end

  def or(dst,src)
    dst |= src
  end

  def xor(dst, src)
    dst ^= src
  end

  def not(dst)
    #. 1's complement
    dst = ~dst
  end

  # does this mean give us the signed negative of an unsigned number?
  def neg(dst)
    #. 2's complement

    # http://www.cs.fsu.edu/~hawkes/cda3101lects/chap4/negation.html
    dst = ~dst + 1
  end

  def cld()
    set_df(false)
  end

  def std()
    set_df(true)
  end

  def stc()
    set_cf(true)
  end

  def clc()
    set_cf(false)
  end

  #def sidt(r)
  #  self.IDT = r
  #end

  # for manual in-out.
  # http://bochs.sourceforge.net/techspec/PORTS.LST

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


  # http://x86.renejeschke.de/html/file_module_x86_id_295.html
  # ULTRAVIOLENCE : should this be implemented in memory.rb for fast
  # context switching? either way, we can move it around later
  def lidt(r)
    newIDTLength_b = @mem[r].read(2)
    newIDTLength = newIDTLength_b.ord + newIDTLength_b[1].ord * 0x100
    newIDT = @mem[r + 2].read(4)
    newIDTVal = newIDT[0].ord + newIDT[1].ord * 0x100 + newIDT[2].ord * 0x10000 + newIDT[3].ord * 0x1000000
    @IDT = newIDTVal
    @IDTLength = newIDTLength
  end

  def sidt(r)
    # @mem.set(r,[0xFF,0xFE].pack('c*'),2)
    newIDTLengthBytes = [@IDTLength & 0xFF, (@IDTLength & 0xFF00) / 0x100].pack('c*')
    newIDTBytes = [
      @IDT & 0xFF,
      (@IDT & 0xFF00) / 0x100,
      (@IDT & 0xFF0000) / 0x10000,
      (@IDT & 0xFF000000) / 0x1000000
    ]
    @mem[r].write(newIDTLengthBytes,2)
    @mem[r+2].write(newIDTBytes,4)
  end

  def interrupt(intNum)
    newIDTPtr = MemPointer.new(@mem,@IDT + intNum * (IDTDescriptor.new.num_bytes))
    newIDTDescriptor = IDTDescriptor.read(newIDTPtr)
    @eip = newIDTDescriptor.offset_1 * 0x10000 + newIDTDescriptor.offset_2
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

  # carry
  def set_cf(v)
  end

  # zero/equal
  def set_zf(v)
  end

  # sign
  def set_sf(v)
  end

  # parity
  def set_pf(v)
  end

  # direction
  def set_df(v)
  end

  # auxiliary
  def set_af(v)
  end

  # overflow
  def set_of(v)
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
