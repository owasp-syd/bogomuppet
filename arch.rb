class Architecture
  attr_reader :bits, :bytes, :mask

  @@tokens = {
    bit:      0x01, #. binary digit               / bit
    nybble:   0x04, #. half byte per nybble       /
    byte:     0x08, #.  8 bits per byte            /
    word:     0x10, #.  2 bytes per word  (16-bit) / short int
    dword:    0x20, #.  4 bytes per dword (32-bit) /       int
    qword:    0x40, #.  8 bytes per qword (64-bit) / long long
    xmmword:  0x80, #. 16 bytes per xmmword SSE XMM registers, paragraph
    ymmword: 0x100, #. 32 bytes per ymmword SSE XMM registers, double paragraph
    BYTE:     0x01, #.  1 bytes per byte           /
    WORD:     0x02, #.  2 bytes per word  (16-bit) /
    DWORD:    0x04, #.  4 bytes per dword (32-bit) /
    QWORD:    0x08, #.  8 bytes per qword (64-bit) /
  }

  def self.[](key) @@tokens[key] end
  def [](key) self.class[key] end
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
