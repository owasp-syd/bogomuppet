class Pointer
  @@mem = nil

  attr_accessor :addr

  def initialize(mem, addr)
    @@mem = mem
    @addr = addr
  end

  def to_s
    return sprintf("ptr:%0#10x", @addr)
  end

  def write(data, size)
    return @@mem.set(@addr, data, size)
  end
end

class Memory
  def initialize(arch)
    @arch = arch
    @data = Array.new(0)
  end

  def [](addr) self.get(addr, 0) end
  def get(addr,  bytes=0)
    byte = Pointer.new(self, addr)
    if bytes == 0
      return byte.nil? ? 0x0 : byte
    else
      return @data[addr...(addr+bytes)].join()
    end
  end

  def []=(addr, data) self.set(addr, data, addr.count) end
  def set(addr, data, size)
    wrote = 0
    data.each_byte do |byte|
      if wrote < size then
        @data[addr + wrote] = byte
        wrote += 1
      else
        break
      end
    end

    return wrote
  end
end
