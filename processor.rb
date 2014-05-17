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
    @arch = Intel32
    @mem  = Memory.new @arch
    Register.mem = @mem

    @eflags = EFLAGS.new

    @eip = EIP.new

    @ebp = EBP.new
    @esp = ESP.new

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
end
