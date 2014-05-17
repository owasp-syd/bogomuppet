#!/usr/bin/env ruby
require_relative 'processor'
require_relative 'memory'

require 'minitest/autorun'

#. Tests -={
#. Registers -={
class TestMath < Minitest::Test
  def setup
    @cpu = Processor.new
  end

  def test_xor
    @cpu.eax = 0xAABBCCDD

    @cpu.eax ^= 0xABABABAB
    assert_equal 0x1106776, @cpu.eax.bits

    @cpu.eax ^= @cpu.eax
    assert_equal 0x0000000, @cpu.eax.bits
  end

  def test_or
    @cpu.eax = 0xAABBCCDD

    @cpu.eax |= 0xAA000000
    assert_equal 0xAABBCCDD, @cpu.eax.bits
  end

  def test_add
    @cpu.eax = 0xAABB0000
    @cpu.ebx = 0x0000CCDD

    @cpu.eax += @cpu.ebx
    assert_equal 0xAABBCCDD, @cpu.eax.bits
  end

  def test_sub
    @cpu.eax = 0xAABBCCDD
    @cpu.ebx = 0x0000CCDD

    @cpu.eax -= @cpu.ebx
    assert_equal 0xAABB0000, @cpu.eax.bits
  end

  # http://web.itu.edu.tr/kesgin/mul06/intel/instr/mul.html
  def _test_mul
    @cpu.eax = 0xAABBCCDD
    @cpu.ebx = 0xBB
    @cpu.ecx = 0
    @cpu.edx = 0
    #@cpu.eax *= @cpu.ebx
    @cpu.ebx.mul()
    assert_equal 0xb72ea56f,@cpu.eax.bits
    assert_equal 0x0018FF50,@cpu.ebx.bits
    assert_equal 0,@cpu.ecx.bits
    assert_equal 0x7c,@cpu.edx.bits
  end

  def _test_div
    @cpu.eax = 0xAABBCCDD
    @cpu.ebx = 0
    @cpu.ecx = 2
    @cpu.edx = 0
    @cpu.ecx.div()
    assert_equal 0x555de66e,@cpu.eax.bits
    assert_equal 0x0018ff50,@cpu.ebx.bits
    assert_equal 0x00000002,@cpu.ecx.bits
    assert_equal 1,@cpu.edx.bits
  end

  # http://web.itu.edu.tr/kesgin/mul06/intel/instr/imul.html
  def _test_mathImul
    @cpu.eax = 0xFFABCCDD
    @cpu.ebx = 0xBB
    @cpu.ecx = 0
    @cpu.edx = 0
    @cpu.ebx.imul()
    assert_equal 0xc27ea56f,@cpu.eax.bits
    assert_equal 0x0018ff50,@cpu.ebx.bits
    assert_equal 0,@cpu.ecx.bits
    assert_equal 0xffffffff,@cpu.edx.bits
  end

  def _test_mathIdiv
    @cpu.eax = 0xAABBCCDD
    @cpu.ebx = 0
    @cpu.ecx = 2
    @cpu.edx = 0
    @cpu.ecx.idiv()
    assert_equal 0x555de66e,@cpu.eax.bits
    assert_equal 0x0018ff50,@cpu.ebx.bits
    assert_equal 2,@cpu.ecx.bits
    assert_equal 1,@cpu.edx.bits
  end
end
#. }=-
#. Memory -={
class TestMem < Minitest::Test
  def setup
    @cpu = Processor.new
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
#. Stack -=
class TestStack < Minitest::Test
  def setup
    @cpu = Processor.new
    @stack = @cpu.stack
  end

  def test_stack_pointer
    assert_equal 0xFFFF0000, @stack.base.addr
    assert_equal 0xFFFF0000, @stack.stack.addr

    @stack.push  0x51525354
    assert_equal 0xFFFF0000, @stack.base.addr
    assert_equal 0xFFFEFFFC, @stack.stack.addr

      @stack.push  0x61626364
      assert_equal 0xFFFEFFF8, @stack.stack.addr

        @stack.push  "\x41\x42\x43\x44"
        assert_equal 0xFFFEFFF4, @stack.stack.addr

    assert_equal 0xFFFF0000, @stack.base.addr

        assert_equal "\x41\x42\x43\x44", @stack.pop
        assert_equal 0xFFFEFFF8, @stack.stack.addr

      assert_equal "\x64\x63\x62\x61", @stack.pop
      assert_equal 0xFFFEFFFC, @stack.stack.addr

    assert_equal "\x54\x53\x52\x51", @stack.pop
    assert_equal 0xFFFF0000, @stack.stack.addr

    assert_equal 0xFFFF0000, @stack.base.addr
  end
end
#. }=-
#. }=-
