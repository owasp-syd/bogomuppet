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

  def -(bytes)
    @addr -= bytes

    return self
  end

  def +(bytes)
    @addr += bytes

    return self
  end

  def read(size)
    return @@mem.get(@addr, size)
  end

  def write(data, size)
    return @@mem.set(@addr, data, size)
  end
end

class Memory
  def initialize(arch)
    @arch = arch
    @data = Hash.new("\x00")
  end

  def [](addr) self.get(addr, 0) end
  def get(addr,  bytes=0)
    if bytes == 0
      return Pointer.new(self, addr)
    else
      return (addr...(addr+bytes)).map { |addr| @data[addr] }.join
    end
  end

  def []=(addr, data) self.set(addr, data, addr.count) end
  def set(addr, data, size)
    wrote = 0

    #. Convert integer to string first
    case data
      when Integer
        data = [data & @arch.mask].pack('V*')
      when Register
        data = [data.bits & @arch.mask].pack('V*')
    end

    data.each_char do |byte|
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

class Stack
  attr_reader :base, :stack

  def initialize(arch, mem)
    @arch  = arch
    @mask  = (@arch.bits << 1) - 1
    @mem   = mem
    @base  = @mem[0xFFFF0000]
    @stack = @mem[0xFFFF0000]
  end

  def push(data)
    @stack.write(data, @arch.bytes)
    @stack -= @arch.bytes
  end

  def pop
    @stack += @arch.bytes
    return @stack.read(@arch.bytes)
  end

  def to_s
    return "#{@stack}: #{@stack.read(1)}"
  end
end
