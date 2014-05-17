class Architecture
  attr_reader :bits, :bytes, :mask

  @@tokens = {
    bit:     0x01,
    nybble:  0x04, #. half byte per nybble
    byte:    0x08, #. 8 bits per byte
    word:    0x10, #. 2 bytes per word  (16-bit)
    dword:   0x20, #. 4 bytes per dword (32-bit)
    qword:   0x40, #. 8 bytes per qword (64-bit)
  }

  def self.[](key) @@tokens[key] end

  def mask()  ((1 << @bits) - 1)  end
  def bytes() (@bits / @@tokens[:byte]) end
end

class IA32 < Architecture
  def initialize
    @bits  = 32
  end
end

class IA64 < Architecture
  def initialize
    @bits  = 64
  end
end
