require_relative 'arch'
require_relative 'memory'
require_relative 'register'

class Processor
  attr_accessor :mem

  attr_accessor :eax, :ax, :al, :ah
  attr_accessor :ebx, :bx, :bl, :bh
  attr_accessor :ecx, :cx, :cl, :ch
  attr_accessor :edx, :dx, :dl, :dh

  attr_accessor :esi, :edi, :ebp

  def initialize
    @arch = Intel32
    @mem  = Memory.new @arch

    Register.mem = @mem

    #. General Registers -={
    @eax = Register.new(:EAX, 0x20)   #. 32-bit Accumulator Registers
    @ax  = @eax.register(:AX, 0xFFFF) #. 16-bit Accumulator Registers
    @al  = @eax.register(:AL, 0x00FF) #.  8-bit Accumulator Registers
    @ah  = @eax.register(:AH, 0xFF00) #.  8-bit Accumulator Registers

    @ebx = Register.new(:EBX, 0x20)   #. 32-bit Base Registers
    @bx  = @ebx.register(:BX, 0xFFFF) #. 16-bit Base Registers
    @bl  = @ebx.register(:BL, 0x00FF) #.  8-bit Base Registers
    @bh  = @ebx.register(:BH, 0xFF00) #.  8-bit Base Registers

    @ecx = Register.new(:ECX, 0x20)   #. 32-bit Counter Registers
    @cx  = @ecx.register(:CX, 0xFFFF) #. 16-bit Counter Registers
    @cl  = @ecx.register(:CL, 0x00FF) #.  8-bit Counter Registers
    @ch  = @ecx.register(:CH, 0xFF00) #.  8-bit Counter Registers

    @edx = Register.new(:EDX, 0x20)   #. 32-bit Data Registers
    @dx  = @edx.register(:DX, 0xFFFF) #. 16-bit Data Registers
    @dl  = @edx.register(:DL, 0x00FF) #.  8-bit Data Registers
    @dh  = @edx.register(:DH, 0xFF00) #.  8-bit Data Registers
    #. }=-

    #. Segment Registers -={
    @esi = Register.new(:ESI, 0x20) #.
    @edi = Register.new(:EDI, 0x20) #.
    @ebp = Register.new(:EBP, 0x20) #. Base Pointer
    @eip = Register.new(:EIP, 0x20) #. Instruction Pointer
    @esp = Register.new(:ESP, 0x20) #. Stack Pointer
    #. }=-

    #. Indicators -={
    #. }=-
  end

  def eax=(data) @eax.write(data) end
  def ebx=(data) @ebx.write(data) end
  def ecx=(data) @ecx.write(data) end
  def edx=(data) @edx.write(data) end

  def esi=(data) @edx.write(data) end
end
