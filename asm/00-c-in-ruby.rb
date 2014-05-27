#!/usr/bin/env ruby
require 'inline'

class Cee
  inline(:C) do |builder|
    builder.include '<stdlib.h>'
    builder.include '<string.h>'
    builder.include '<libdis.h>'

    builder.add_compile_flags '-ldisasm'

    builder.prefix <<-eos
      /* lang:c */
      #define BIT(n)               ( 1   <<    (n))
      #define BIT_SET(bf, mask)    ((bf) |  (mask))
      #define BIT_CLR(bf, mask)    ((bf) & ~(mask))
      #define BIT_FLP(bf, mask)    ((bf) ^  (mask))
      #define BIT_MSK(size)        (BIT(size) - 1 )

      #define ASMBUFSIZ 32
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

    builder.c <<-eos, method_name: 'disasm', arity: 1
      /* lang:c */
      VALUE disasm(char *bytes) {
        VALUE res = 0;
        unsigned int pos = 0, size;
        char line[128] = { 0 };
        char *ptr = line;
        x86_insn_t insn;
        x86_init(opt_none, NULL, stderr);
        if((size = x86_disasm((unsigned char *)bytes, 0xFF, 0, pos, &insn))) {
          x86_format_insn(&insn, ptr, ASMBUFSIZ, intel_syntax);
          ptr += strlen(line);
          pos += size;
          res = rb_str_new(line, strlen(line));
        }
        x86_cleanup();
        return res;
      }
      /* lang:c */
    eos
  end

  def initialize
    @bits = 0x0
  end
end

c = Cee.new
p c.disasm("\x83\x7d\xf0\x01")
p c.disasm("\xe8\xfc\xff\xff\xff")
p c.disasm("\x89\x04\x24")
p c.disasm("\xc7\x44\x24\x04\x00\x00\x00")
