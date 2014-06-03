require_relative 'pe'
require_relative 'elf'

class Pointer
  @@mem = nil

  attr_accessor :addr

  def initialize(mem, addr, size=nil)
    @@mem = mem
    @addr = addr
    @size = size #. optional default size for r/w
  end

  def to_s
    return sprintf("ptr:%0#10x", @addr)
  end

  def -(bytes)
    @addr -= bytes

    return self
  end

  def +(bytes)
    @addr += bytes
    return self
  end

  def size(s=nil)
    case s
      when Integer then size = s
      when :BYTE, :WORD, :DWORD then size = @@mem.arch[s]
      when nil then size = @size
    end
    raise SyntaxError if size.nil?
    return size
  end

  def read(size=nil)
    return @@mem.get(@addr, size(size))
  end

  def write(data, size=nil)
    return @@mem.set(@addr, data, size(size))
  end

  def byte
    @size = @@mem.arch[:byte]
    return self
  end

  def word
    @size = @@mem.arch[:word]
    return self
  end

  def dword
    @size = @@mem.arch[:dword]
    return self
  end
end

class MemPointer < Pointer
  def read(size=nil)
    datachunk = @@mem.get(@addr, size(size))
    @addr += size(size)
    return datachunk
  end

  def write(data, size=nil)
    if size == nil
      retVal = @@mem.set(@addr, data, data.length)
      @addr += data.length
      return retVal
    else
      retVal = @@mem.set(@addr, data, size(size))
      @addr += size(size)
      return retVal
    end
  end

end

class Memory
  attr_reader :arch
  def initialize(arch)
    @arch = arch
    @data = Hash.new("\x00")
  end

  def loader(filename, loc=nil)
    if loc != nil
      # just stick a binary into memory
      filedata = File.read(filename)
      set(loc, filedata, filedata.bytesize)
      return loc
    end
    retVal = loaderPE(filename)
    if retVal == 0
      retVal = loaderElf(filename)
    end
    return retVal
  end

  # Despite the complexity of the elf file, only the elf hdr and the program
  # header actually matter.  Not bothering to load section info for now, but we
  # can easily add it in (or even read from memory - but that's just for human
  # readability purposes.
  def loaderElf(filename)
    imageBase = 0

    file = File.open(filename,"rb")
    ehdr = Elf32_Ehdr.read(file)
    if(ehdr.e_ident[0] == 0x7f and
        ehdr.e_ident[1] == 0x45 and
        ehdr.e_ident[2] == 0x4c and
        ehdr.e_ident[3] == 0x46
    )
      file.seek(ehdr.e_phoff,IO::SEEK_SET)
      imageBase = ehdr.e_entry
      programHeaders = Array.new
      (0 .. (ehdr.e_phnum - 1)).each do
        phdr = Elf32_Phdr.read(file)
        programHeaders << phdr
        if phdr.p_offset == 0 and phdr.p_vaddr != 0
          imageBase = phdr.p_vaddr
        end
      end

      for programHeader in programHeaders do
        # The final section will be 0(size:0) to 0(size:0), at least in multitool
        # so do not attempt to map this.
        if programHeader.p_vaddr == 0
          next
        end
        file.seek(programHeader.p_offset,IO::SEEK_SET)
        binChunk = file.read(programHeader.p_filesz)
        newSectionPtr = MemPointer.new(self,programHeader.p_vaddr)
        newSectionPtr.write(binChunk)
      end
    end

    file.close()

    return imageBase
  end

  def loaderPE(filename)
    imageBase = 0

    file = File.open(filename,"rb")
    imgDosHdr = IMAGE_DOS_HEADER.read(file)
    if imgDosHdr.e_magic == 0x5a4d
      file.seek(imgDosHdr.e_lfanew,IO::SEEK_SET)
      imgNtHdrs = IMAGE_NT_HEADERS.read(file)
      imageBase = imgNtHdrs.optionalHeader.imageBase
      doshdrptr = MemPointer.new(self, imageBase)
      imgDosHdr.write(doshdrptr)
      nthdrsptr = MemPointer.new(self, imageBase + imgDosHdr.e_lfanew)
      imgNtHdrs.write(nthdrsptr)
      sectionTable = Array.new
      writtenSections = 0
      (0..imgNtHdrs.fileHeader.numberOfSections - 1).each do
        newSection = IMAGE_SECTION_HEADER.read(file)
        sectionTable << newSection
        newSectionPtr = MemPointer.new(
          self,
          imageBase +
            imgDosHdr.e_lfanew +
            imgNtHdrs.to_binary_s.length +
            writtenSections * newSection.to_binary_s.length
        )
        newSection.write(newSectionPtr)
        writtenSections += 1
      end

      for section in sectionTable do
        file.seek(section.pointerToRawData)
        sectionData = file.read(section.sizeOfRawData)
        set(imageBase + section.virtualAddress,sectionData,section.sizeOfRawData)
      end
    end

    file.close()
    return imageBase
  end

  def [](addr) self.get(addr, 0) end
  def get(addr,  bytes=0)
    if bytes == 0
      return Pointer.new(self, addr)
    else
      return (addr...(addr+bytes)).map { |addr| @data[addr] }.join
    end
  end

  def []=(addr, data) self.set(addr, data, addr.count) end
  def set(addr, data, size)
    wrote = 0

    #. Convert integer to string first
    case data
      when Integer
        data = [data & @arch.mask].pack('V*')
      when Register
        data = [data.read & @arch.mask].pack('V*')
    end

    data.each_char do |byte|
      if wrote < size then
        @data[addr + wrote] = byte
        wrote += 1
      else
        break
      end
    end

    return wrote
  end
end
