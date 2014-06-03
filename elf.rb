require 'bindata'

# Do not need section header yet.
class Elf32_Ehdr < BinData::Record
  endian :little
  EI_NIDENT = 16
  array :e_ident, :initial_length => EI_NIDENT do uint8 end
  uint16 :e_type
  uint16 :e_machine
  uint32 :e_version
  uint32 :e_entry
  uint32 :e_phoff
  uint32 :e_shoff
  uint32 :e_flags
  uint16 :e_hsize
  uint16 :e_phentsize
  uint16 :e_phnum
  uint16 :e_shentsize
  uint16 :e_shnum
  uint16 :e_shstrndx
end

class Elf32_Phdr < BinData::Record
  endian :little
  uint32 :p_type
  uint32 :p_offset
  uint32 :p_vaddr
  uint32 :p_paddr
  uint32 :p_filesz
  uint32 :p_memsz
  uint32 :p_flags
  uint32 :p_align
end

class Elf32_Shdr < BinData::Record
  endian :little
  uint32 :sh_name
  uint32 :sh_type
  uint32 :sh_flags
  uint32 :sh_addr
  uint32 :sh_offset
  uint32 :sh_size
  uint32 :sh_link
  uint32 :sh_info
  uint32 :sh_addralign
  uint32 :sh_entsize
end
