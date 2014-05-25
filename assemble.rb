#!/usr/bin/env ruby

require_relative 'processor'

require 'parslet'
class Assembler < Parslet::Parser
  rule(:eol)         { str("\n") | any.absent? }
  rule(:ws)          { match('[\s\t]').repeat(1) }
  rule(:delim)       { ws.maybe >> str(',') >> ws.maybe }
  rule(:comment)     { str(";") >> any.repeat }

  rule(:reg)         {
    str('ah')  | str('bh')  | str('ch')  | str('dh')  |
    str('al')  | str('bl')  | str('cl')  | str('dl')  |
    str('ax')  | str('bx')  | str('cx')  | str('dx')  |
    str('eax') | str('ebx') | str('ecx') | str('edx') |
    str('edi') | str('esi') | str('ebp') | str('esp')
  }
  rule(:regseg)      {
    (
      str('cs') |
      str('ds') | str('ss') | str('es') |
      str('fs') | str('gs')
    ).as(:regseg) >> str(':')
  }
  rule(:imm)         { str('0x') >> match('[0-9a-f]').repeat(1) }
  rule(:decimal)     { match('[0-9]').repeat(1) }
  rule(:opmath)      { match('[-+*]') }
  rule(:ptrstr)      {
    ( str('BYTE') | str('WORD') | str('DWORD') ) >> ws >> str('PTR')
  }
  rule(:ptrdrf)      {
    regseg.maybe >>
    str('[') >> (
      (
        reg.as(:reg) | mem
      ) >> (
        opmath.as(:op) >> ( reg.as(:reg) | imm.as(:imm) | decimal.as(:int) )
      ).repeat
    ) >> str(']')
  }
  rule(:mem)         {
    ptrstr >> ws >> ptrdrf.as(:ptr) | imm.as(:imm)
  }
  rule(:opsrc)       { reg.as(:reg) | mem | imm.as(:imm) }
  rule(:opdst)       { reg.as(:reg) | mem }

  rule(:mov)         {
    str('mov').as(:opcode) >> ws >> opdst.as(:opdst) >> delim >> opsrc.as(:opsrc)
  }
  rule(:add)         {
    str('add').as(:opcode) >> ws >> opdst.as(:opdst) >> delim >> opsrc.as(:opsrc)
  }

  rule(:expr)        { mov | add }
  rule(:line)        { expr.maybe >> comment.maybe >> eol }
  root :line
end

def get_instructions(inst)
  data = [
    "add    DWORD PTR ss:[eax],0x7f1d00",
  ]

  data += %x(
    objdump -Mintel -d ../multitool/libdis/libdis.so
  ).split("\n").select { |line|
    line.split("\t").count == 3
  }.map { |line|
    line.split("\t")[2] unless line.nil?
  }.select { |expr|
    expr =~ /^#{inst.to_s}\s+/
  }

  return data
end

require 'pp'
class Assemble
  def initialize(file)
    @cpu = Processor.new
    @asm = Assembler.new
    #@code = File.open(file).read
  end

  def test_instruction(inst)
    i = 0
    code = get_instructions(inst)
    code.each do |statement|
      printf "%05d. #{statement.red}...", i += 1
      parsed = @asm.parse "#{statement}"
      printf "#{parsed}\n".green
    end
  rescue Parslet::ParseFailed => failure
    puts failure.cause.ascii_tree
  end
end

ass = Assemble.new ARGV[0]
ass.test_instruction :mov
ass.test_instruction :add
