class Pointer
  @@mem = nil

  attr_accessor :addr

  def initialize(mem, addr)
    @@mem = mem
    @addr = addr
  end

  def [](i)
    if i.is_a? Register
      return @@mem[@addr + i.bits]
    else
      return @@mem[@addr + i]
    end
  end

  def []=(i, v)
    if i.is_a? Register
      @@mem[@addr + i.bits] = v
    else
      @@mem[@addr + i] = v
    end
  end

  def to_s
    return sprintf("ptr:%0#10x", @addr)
  end

  def write(data)
    if defined? data.each_char
      data = data.each_char.map { |c| c.ord }
    end

    data.each_with_index { |byte, i| @@mem[@addr+i] = byte }

    return data.length
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

  def []=(addr, v) self.set(addr, v, addr.count) end
  def set(addr, v, size)
    i = 0
    v.each_char do |byte|
      @data[addr + i] = byte
      i += 1
    end
  end
end
