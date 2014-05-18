class Pointer
  @@mem = nil

  attr_accessor :addr

  def initialize(mem, addr, size=nil)
    @@mem = mem
    @addr = addr
    @size = size #. optional default size for r/w
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

  def size(s=nil)
    case s
      when Integer then size = s
      when :BYTE, :WORD, :DWORD then size = @@mem.arch[s]
      when nil then size = @size
    end
    raise SyntaxError if size.nil?

    return size
  end

  def read(size=nil)
    return @@mem.get(@addr, size(size))
  end

  def write(data, size=nil)
    return @@mem.set(@addr, data, size(size))
  end

  def byte
    @size = @@mem.arch[:byte]
    return self
  end

  def word
    @size = @@mem.arch[:word]
    return self
  end

  def dword
    @size = @@mem.arch[:dword]
    return self
  end
end

class Memory
  attr_reader :arch

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
        data = [data.read & @arch.mask].pack('V*')
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
