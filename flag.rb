require 'colorize'

require_relative 'util'

class Flag
  def initialize(reg, mask, name, type, desc)
    @register = reg
    @name = name
    @type = type
    @desc = desc
    @mask = mask
    @size = bits_set(mask)
    @color = String.colors[@name.hash % String.colors.count]

    @pstart = 0
    while @mask & (1 << @pstart) == 0
      @pstart += 1
    end
    @pend = @pstart + @size - 1
  end

  def write(value)
    @register.bitfield.write(value, @mask)
  end

  def read
    return ((@register.read & @mask) >> mask_lshift_width(@mask)).to_i
  end

  def to_s
    i = 0
    s = []
    ("%0#{@size}b" % self.read).each_char.map { |bit|
      c = @name.to_s[i]
      s << (bit == '1' ? c.upcase.bold : c.downcase)
      i += 1
    }
    return s.join.colorize(@color)
  end
end
