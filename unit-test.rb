#!/usr/bin/env ruby
require_relative 'processor'
require_relative 'memory'

require 'minitest/autorun'

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
