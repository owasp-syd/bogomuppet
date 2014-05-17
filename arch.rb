class Intel32
  @@bits   = 32
  @@bytes  = 4
  @@tokens = {
    bit:     0x01,
    nybble:  0x04, #. half byte per nybble
    byte:    0x08, #. 8 bits per byte
    word:    0x10, #. 2 bytes per word  (16-bit)
    dword:   0x20, #. 4 bytes per dword (32-bit)
    qword:   0x40, #. 8 bytes per qword (64-bit)
  }
  def self.bits()  @@bits  end
  def self.bytes() @@bytes end
  def self.[](key) @@tokens[key] end
end
