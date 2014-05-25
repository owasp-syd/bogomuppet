class Cee
  inline(:C) do |builder|
    builder.prefix <<-eos
      /* lang:c */
      #define BIT(n)               ( 1   <<    (n))
      #define BIT_SET(bf, mask)    ((bf) |  (mask))
      #define BIT_CLR(bf, mask)    ((bf) & ~(mask))
      #define BIT_FLP(bf, mask)    ((bf) ^  (mask))
      #define BIT_MSK(size)        (BIT(size) - 1 )
      /* lang:c */
    eos
    builder.c <<-eos
      /* lang:c */
      unsigned int bit_on(unsigned int bitfield, unsigned int pos) {
        return BIT_SET(bitfield, BIT(pos));
      }
      /* lang:c */
    eos
    builder.c <<-eos
      /* lang:c */
      unsigned int bit_off(unsigned int bitfield, unsigned int pos) {
        return BIT_CLR(bitfield, BIT(pos));
      }
      /* lang:c */
    eos
    builder.c <<-eos
      /* lang:c */
      unsigned int bit_flip(unsigned int bitfield, unsigned int pos) {
        return BIT_FLP(bitfield, BIT(pos));
      }
      /* lang:c */
    eos
    builder.c <<-eos
      /* lang:c */
      unsigned int bit_mask(unsigned int bitfield, unsigned int size) {
        return bitfield & BIT_MSK(size);
      }
      /* lang:c */
    eos

  end
  def initialize
    @bits = 0x0
  end

  def bits(mask)
    return bit_mask(@bits, mask)
  end
end
