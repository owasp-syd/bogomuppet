require 'colorize'

require_relative 'util'

class Flag
  def initialize(reg, mask, name, type, desc)
    @register = reg
    @name = name
    @type = type
    @desc = desc
    @mask = mask
    @size = bitsSetInDWORD(mask)
    @color = String.colors[@name.hash % String.colors.count]

    @pstart = 0
    while @mask & (1 << @pstart) == 0
      @pstart += 1
    end
    @pend = @pstart + @size - 1
  end

  def value
    return @register.read & @mask
  end

  def to_s
    i = 0
    s = []
    self.value.to_s(2).each_char.map { |bit|
      c = @name.to_s[i]
      s << (bit == 1 ? c.upcase.bold : c.downcase)
      i += 1
    }
    return s.join.colorize(@color)
  end
end
