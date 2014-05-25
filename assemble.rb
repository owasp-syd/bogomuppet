#!/usr/bin/env ruby

require_relative 'processor'

require 'parslet'
class Assembler < Parslet::Parser
  rule(:eol)         { str("\n") | any.absent? }
  rule(:ws)          { match('[\s\t]').repeat(1) }
  rule(:delim)       { ws.maybe >> str(',') >> ws.maybe }
  rule(:comment)     { str(";") >> any.repeat }

  rule(:regseg)      {
    (
      str('cs') | str('fs') | str('gs') |
      str('ds') | str('ss') | str('es')
    ).as(:regseg) >> str(':')
  }
  rule(:regb)         {
    str('ah')  | str('bh')  | str('ch')  | str('dh')  |
    str('al')  | str('bl')  | str('cl')  | str('dl')
  }
  rule(:regw)         {
    str('ax')  | str('bx')  | str('cx')  | str('dx')  |
      str('cs') | str('fs') | str('gs') |
      str('ds') | str('ss') | str('es')
  }
  rule(:regd)         {
    str('eax') | str('ebx') | str('ecx') | str('edx') |
    str('edi') | str('esi') | str('ebp') | str('esp')
  }
  rule(:reg)         { regb | regw | regd }

  rule(:imm)         { str('0x') >> match('[0-9a-f]').repeat(1) }
  rule(:decimal)     { match('[0-9]').repeat(1) }
  rule(:opmath)      { match('[-+*]') }
  rule(:ptrdrf)      {
    regseg.maybe >>
    str('[') >> (
      (
        reg.as(:reg)
      ) >> (
        opmath.as(:op) >> ( reg.as(:reg) | imm.as(:imm) | decimal.as(:int) )
      ).repeat
    ) >> str(']')
  }

  rule(:memb)        { str('BYTE') >> ws >> str('PTR') >> ws >> ptrdrf.as(:ptr) }
  rule(:memw)        { str('WORD') >> ws >> str('PTR') >> ws >> ptrdrf.as(:ptr) }
  rule(:memd)        { str('DWORD') >> ws >> str('PTR') >> ws >> ptrdrf.as(:ptr) }
  rule(:mem)         { memb | memw | memd }

  #. <op> <reg>|<mem>, <reg>|<imm> -={
  rule(:opdstAb)      { regb.as(:reg) | memb.as(:mem) }
  rule(:opsrcAb)      { regb.as(:reg) | imm.as(:imm) }

  rule(:opdstAw)      { regw.as(:reg) | memw.as(:mem) }
  rule(:opsrcAw)      { regw.as(:reg) | imm.as(:imm) }

  rule(:opdstAd)      { regd.as(:reg) | memd.as(:mem) }
  rule(:opsrcAd)      { regd.as(:reg) | imm.as(:imm) }
  #. }=-

  #. <op> <reg>, <reg>|<mem>|<imm> -={
  rule(:opdstBb)      { regb.as(:reg) }
  rule(:opsrcBb)      { regb.as(:reg) | memb.as(:mem) | imm.as(:imm) }

  rule(:opdstBw)      { regw.as(:reg) }
  rule(:opsrcBw)      { regw.as(:reg) | memw.as(:mem) | imm.as(:imm) }

  rule(:opdstBd)      { regd.as(:reg) }
  rule(:opsrcBd)      { regd.as(:reg) | memd.as(:mem) | imm.as(:imm) }
  #. }=-

  rule(:mov)         {
    str('mov').as(:opcode) >> ws >> opdstAb.as(:opdst) >> delim >> ( opsrcAb ).as(:opsrc) |
    str('mov').as(:opcode) >> ws >> opdstAw.as(:opdst) >> delim >> ( opsrcAw ).as(:opsrc) |
    str('mov').as(:opcode) >> ws >> opdstAd.as(:opdst) >> delim >> ( opsrcAd ).as(:opsrc) |
    str('mov').as(:opcode) >> ws >> opdstBb.as(:opdst) >> delim >> ( opsrcBb ).as(:opsrc) |
    str('mov').as(:opcode) >> ws >> opdstBw.as(:opdst) >> delim >> ( opsrcBw ).as(:opsrc) |
    str('mov').as(:opcode) >> ws >> opdstBd.as(:opdst) >> delim >> ( opsrcBd ).as(:opsrc)
  }
  rule(:add)         {
    str('add').as(:opcode) >> ws >> opdstAb.as(:opdst) >> delim >> ( opsrcAb ).as(:opsrc) |
    str('add').as(:opcode) >> ws >> opdstAw.as(:opdst) >> delim >> ( opsrcAw ).as(:opsrc) |
    str('add').as(:opcode) >> ws >> opdstAd.as(:opdst) >> delim >> ( opsrcAd ).as(:opsrc) |
    str('add').as(:opcode) >> ws >> opdstBb.as(:opdst) >> delim >> ( opsrcBb ).as(:opsrc) |
    str('add').as(:opcode) >> ws >> opdstBw.as(:opdst) >> delim >> ( opsrcBw ).as(:opsrc) |
    str('add').as(:opcode) >> ws >> opdstBd.as(:opdst) >> delim >> ( opsrcBd ).as(:opsrc)
  }

  rule(:expr)        { mov | add }
  rule(:line)        { expr.maybe >> comment.maybe >> eol }
  root :line
end

def get_instructions(inst)
  data = [
    "add    eax,ebx",
    "add    eax,0xffaabbcc",
    "add    eax,DWORD PTR [eax]",
    "add    DWORD PTR [eax],ebx",

    "add    DWORD PTR ss:[eax],0x7f1d00",
    "mov    WORD PTR [eax],es",
  ]

  data += %x(
    objdump -Mintel -d ../multitool/libdis/libdis.so
  ).split("\n").select { |line|
    line.split("\t").count == 3
  }.map { |line|
    line.split("\t")[2] unless line.nil?
  }.select { |expr|
    expr =~ /^#{inst.to_s}\s+/
  }.select { |expr|
    expr !~ /eiz/
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
