#!/usr/bin/env ruby
require_relative 'processor'
require_relative 'memory'

require 'minitest/autorun'

#. Tests -={
#. Memory -={
class TestMemory < Minitest::Test
  def setup
    @cpu = Intel32.new
    @mem = @cpu.mem
  end

  def test_mem
    addr = 0x0400f000
    @mem.set(addr, "\xAA\xBB\xCC\xDD\x11\x00\x44\x33", 8)
    assert_equal "\xAA\xBB\xCC\xDD", @mem.get(addr, 4)

    addr = 0x0400e000
    @mem.set(addr, 0x41424344, 4)
    assert_equal "DCBA", @mem.get(addr, 4)
  end
end
#. }=-
#. Processor:Registers -={
class TestSubRegisters < Minitest::Test
  def setup
    @cpu = Intel32.new
  end

  def test_gpr
    @cpu.eax = 0xAABBFFDD
    assert_equal 0xAABBFFDD, @cpu.eax.read

    @cpu.ah += 1
    assert_equal 0xAABB00DD, @cpu.eax.read
    assert_equal 0x00DD, @cpu.ax.read
    assert_equal 0x00, @cpu.ah.read
    assert_equal 0xDD, @cpu.al.read

    @cpu.ebx = @cpu.eax
    assert_equal @cpu.eax.read, @cpu.ebx.read

    @cpu.bh -= 1
    assert_equal 0xAABBFFDD, @cpu.ebx.read
    assert_equal 0xFFDD, @cpu.bx.read
    assert_equal 0xFF, @cpu.bh.read
    assert_equal 0xDD, @cpu.bl.read
  end
end

class TestMath < Minitest::Test
  def setup
    @cpu = Intel32.new
  end

  def test_xor
    @cpu.eax = 0xAABBCCDD

    @cpu.eax ^= 0xABABABAB
    assert_equal 0x1106776, @cpu.eax.read

    @cpu.eax ^= @cpu.eax
    assert_equal 0x0000000, @cpu.eax.read
  end

  def test_or
    @cpu.eax = 0xAABBCCDD

    @cpu.eax |= 0xAA000000
    assert_equal 0xAABBCCDD, @cpu.eax.read
  end

  def test_add
    @cpu.eax = 0xAABB0000
    @cpu.ebx = 0x0000CCDD

    @cpu.eax += @cpu.ebx
    assert_equal 0xAABBCCDD, @cpu.eax.read
  end

  def test_sub
    @cpu.eax = 0xAABBCCDD
    @cpu.ebx = 0x0000CCDD

    @cpu.eax -= @cpu.ebx
    assert_equal 0xAABB0000, @cpu.eax.read
  end

  # http://web.itu.edu.tr/kesgin/mul06/intel/instr/mul.html
  def _test_mul
    @cpu.eax = 0xAABBCCDD
    @cpu.ebx = 0xBB
    @cpu.ecx = 0
    @cpu.edx = 0
    #@cpu.eax *= @cpu.ebx
    @cpu.ebx.mul()
    assert_equal 0xb72ea56f,@cpu.eax.read
    assert_equal 0x0018FF50,@cpu.ebx.read
    assert_equal 0,@cpu.ecx.read
    assert_equal 0x7c,@cpu.edx.read
  end

  def _test_div
    @cpu.eax = 0xAABBCCDD
    @cpu.ebx = 0
    @cpu.ecx = 2
    @cpu.edx = 0
    @cpu.ecx.div()
    assert_equal 0x555de66e,@cpu.eax.read
    assert_equal 0x0018ff50,@cpu.ebx.read
    assert_equal 0x00000002,@cpu.ecx.read
    assert_equal 1,@cpu.edx.read
  end

  # http://web.itu.edu.tr/kesgin/mul06/intel/instr/imul.html
  def _test_mathImul
    @cpu.eax = 0xFFABCCDD
    @cpu.ebx = 0xBB
    @cpu.ecx = 0
    @cpu.edx = 0
    @cpu.ebx.imul()
    assert_equal 0xc27ea56f,@cpu.eax.read
    assert_equal 0x0018ff50,@cpu.ebx.read
    assert_equal 0,@cpu.ecx.read
    assert_equal 0xffffffff,@cpu.edx.read
  end

  def _test_mathIdiv
    @cpu.eax = 0xAABBCCDD
    @cpu.ebx = 0
    @cpu.ecx = 2
    @cpu.edx = 0
    @cpu.ecx.idiv()
    assert_equal 0x555de66e,@cpu.eax.read
    assert_equal 0x0018ff50,@cpu.ebx.read
    assert_equal 2,@cpu.ecx.read
    assert_equal 1,@cpu.edx.read
  end
end
#. }=-
#. Processor:Stack -={
class TestStack < Minitest::Test
  def setup
    @cpu = Intel32.new

    @esp = @cpu.esp
    @ebp = @cpu.ebp

    @eax = @cpu.eax
    @ebx = @cpu.ebx
    @ecx = @cpu.ecx
  end

  def test_stack_pointer
    assert_equal 0xFFFF0000, @ebp.read
    assert_equal 0xFFFF0000, @esp.read

    @cpu.push    0x51525354
    assert_equal 0xFFFF0000, @ebp.read
    assert_equal 0xFFFEFFFC, @esp.read

    @cpu.push    0x61626364
    assert_equal 0xFFFEFFF8, @esp.read

    @cpu.push    "\x41\x42\x43\x44"
    assert_equal 0xFFFEFFF4, @esp.read

    assert_equal 0xFFFF0000, @ebp.read

    @cpu.pop     @eax
    assert_equal 0xFFFEFFF8, @esp.read

    @cpu.pop     @ebx
    assert_equal 0xFFFEFFFC, @esp.read

    @cpu.pop     @ecx
    assert_equal 0xFFFF0000, @esp.read

    assert_equal 0x44434241, @eax.read
    assert_equal 0x61626364, @ebx.read
    assert_equal 0x51525354, @ecx.read

    assert_equal 0xFFFF0000, @ebp.read
  end
end
#. }=-
#. Processor:Instructions -={
class TestProcessor < Minitest::Test
  def setup
    @cpu = Intel32.new
  end

  def test_mov
    #. mov <reg>, <imm>
    @cpu.mov @cpu.eax, 0x51525355
    assert_equal 0x51525355, @cpu.eax.read

    #. mov <reg>, <reg>
    @cpu.mov @cpu.ebx, @cpu.eax
    assert_equal 0x51525355, @cpu.ebx.read

    #. mov <mem>, <reg>
    @cpu.mov @cpu.mem[0xF0FF0000].byte, @cpu.ebx
    assert_equal "\x55\x53\x52\x51", @cpu.mem[0xF0FF0000].read(:DWORD)

    #. mov <reg>, <mem>
    @cpu.mov @cpu.eax, @cpu.mem[0xF0FF0000].byte
    assert_equal 0x51525355, @cpu.ebx.read

    #. mov <mem>, <imm>
    @cpu.mov @cpu.mem[0xF0FF0000].byte, 'BABY'
    assert_equal 'BABY', @cpu.mem[0xF0FF0000].read(:DWORD)
  end

  def test_add
    #. add <reg> <imm>
    @cpu.mov @cpu.eax, 0x80
    @cpu.add @cpu.eax, 0x91
    assert_equal 0x111, @cpu.eax.read

    #. add <reg> <reg>
    @cpu.mov @cpu.eax, 0x34
    assert_equal 0x34, @cpu.eax.read

    @cpu.mov @cpu.ebx, 0x32
    assert_equal 0x32, @cpu.ebx.read

    @cpu.add @cpu.eax, @cpu.ebx
    assert_equal 0x66, @cpu.eax.read
    assert_equal 0x32, @cpu.ebx.read
    assert_equal 0x32, @cpu.bx.read
    assert_equal 0x32, @cpu.bl.read
  end

  def test_sub
    #. sub <reg> <imm>
    @cpu.mov @cpu.eax, 0x80
    @cpu.sub @cpu.eax, 0x6F
    assert_equal 0x11, @cpu.eax.read

    #. add <reg> <reg>
    @cpu.mov @cpu.eax, 0x34
    assert_equal 0x34, @cpu.eax.read

    @cpu.mov @cpu.ebx, 0x32
    assert_equal 0x32, @cpu.ebx.read

    @cpu.sub @cpu.eax, @cpu.ebx
    assert_equal 0x2, @cpu.eax.read
  end
end
#. }=-
#. }=-
