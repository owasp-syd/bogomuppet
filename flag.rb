class Flag
  def initialize(size, name, type, desc)
    @bitfield = nil
    @name = name
    @type = type
    @desc = desc
    @size = size
  end

  def bitfield(bitfield)
    self.bitfield = bitfield
  end
end
