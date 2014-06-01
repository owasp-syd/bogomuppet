require_relative 'memory'
require 'bindata'

class IDTDescriptor < BinData::Record
  endian :little
  uint16 :offset_1
  uint16 :selector
  uint8  :zero
  uint8  :type_attr
  uint16 :offset_2
end

class InterruptDescriptorTable
  @@IDT = nil
  @@IDTSize = 0

  def initialize(memory, idt, idtlength)
    if memory.is_a? Memory
      m = MemPointer.new(memory,idt)
      @IDT = Array.new
      (1..idtlength).each { @IDT << IDTDescriptor.read(m) }
      @IDTSize = idtlength
    else
      raise "IDT needs to be initialized with Memory,Offset,Size"
    end
  end

  def getHandler(intnum)
    handler = nil

    if intnum + 1 <= @IDTSize
      interruptHandler = @IDT[intnum]
      handler = interruptHandler.offset_1 * 0x10000 + interruptHandler.offset_2
    end

    return handler
  end

  def dumpIDT
    if @IDT
      i = 0
      for descriptor in @IDT do
        i += 1
      end
    end
  end
end
