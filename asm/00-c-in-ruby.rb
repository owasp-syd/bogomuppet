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

      #define BUF_SIZE 1024
      #define LINE_SIZE 512
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
      VALUE disasm(VALUE buf) {
        VALUE res;
        x86_init(opt_none, NULL, stderr);
        x86_insn_t insn;
        long arr1_len = RARRAY_LEN(buf);
        VALUE *c_arr1 = RARRAY_PTR(buf);
        int i;
        unsigned int size;
        unsigned int pos = 0;
        unsigned char line[LINE_SIZE];
        for(i=0; i<arr1_len; i++) {
          unsigned char *c = StringValueCStr(c_arr1[i]);
          size = x86_disasm(c, BUF_SIZE, 0, pos, &insn);
          if(size) {
            //print instruction
            x86_format_insn(&insn, &line[0], LINE_SIZE, intel_syntax);
          }
        }
        x86_cleanup();
        return rb_str_new(line, strlen(line));
      }
      /* lang:c */
    eos
  end

  def initialize
    @bits = 0x0
  end
end

c = Cee.new
p c.disasm(["\x55"])
