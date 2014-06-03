require 'bindata'

#. Shamelessly stolen from github (https://gist.github.com/shinaisan/4329239)
#. All credit to "shinaisan"
#. Slightly modified to make it ~includey~

class IMAGE_DOS_HEADER < BinData::Record
  endian   :little
  uint16   :e_magic, :check_value => 0x5A4D, :initial_value => 0x5A4D # MZ
  uint16   :e_cblp
  uint16   :e_cp
  uint16   :e_crlc
  uint16   :e_cparhdr
  uint16   :e_minalloc
  uint16   :e_maxalloc
  uint16   :e_ss
  uint16   :e_sp
  uint16   :e_csum
  uint16   :e_ip
  uint16   :e_cs
  uint16   :e_lfarlc
  uint16   :e_ovno
  array    :_res, :initial_length => 4 do uint16 end
  uint16   :e_oemid
  uint16   :e_oeminfo
  array    :e_res2, :initial_length => 10 do uint16 end
  uint32   :e_lfanew
end

class IMAGE_FILE_HEADER < BinData::Record
  endian   :little
  uint16   :machine
  uint16   :numberOfSections
  uint32   :timeDateStamp
  uint32   :pointerToSymbolTable
  uint32   :numberOfSymbols
  uint16   :sizeOfOptionalHeader
  uint16   :characteristics
end

class IMAGE_DATA_DIRECTORY < BinData::Record
  endian   :little
  uint32   :virtualAddress
  uint32   :tableSize
end

class IMAGE_OPTIONAL_HEADER < BinData::Record
  IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16
  endian   :little
  uint16   :magic
  uint8    :majorLinkerVersion
  uint8    :minorLinkerVersion
  uint32   :sizeOfCode
  uint32   :sizeOfInitializedData
  uint32   :sizeOfUninitializedData
  uint32   :addressOfEntryPoint
  uint32   :baseOfCode
  uint32   :baseOfData
  uint32   :imageBase
  uint32   :sectionAlignment
  uint32   :fileAlignment
  uint16   :majorOperatingSystemVersion
  uint16   :minorOperatingSystemVersion
  uint16   :majorImageVersion
  uint16   :minorImageVersion
  uint16   :majorSubsystemVersion
  uint16   :minorSubsystemVersion
  uint32   :win32VersionValue
  uint32   :sizeOfImage
  uint32   :sizeOfHeaders
  uint32   :checkSum
  uint16   :subsystem
  uint16   :dllCharacteristics
  uint32   :sizeOfStackReserve
  uint32   :sizeOfStackCommit
  uint32   :sizeOfHeapReserve
  uint32   :sizeOfHeapCommit
  uint32   :loaderFlags
  uint32   :numberOfRvaAndSizes
  array    :dataDirectory,
             :type => IMAGE_DATA_DIRECTORY,
             :initial_length => IMAGE_NUMBEROF_DIRECTORY_ENTRIES
end

class IMAGE_NT_HEADERS < BinData::Record
  endian   :little
  uint32   :signature,
             :check_value => 0x00004550,
             :initial_value => 0x00004550 #. PE
  IMAGE_FILE_HEADER     :fileHeader
  IMAGE_OPTIONAL_HEADER :optionalHeader
end

class IMAGE_SECTION_HEADER < BinData::Record
  endian   :little
  IMAGE_SIZEOF_SHORT_NAME = 8

  array    :shortName,
             :initial_length => IMAGE_SIZEOF_SHORT_NAME do uint8 end
  uint32   :virtualSize
  uint32   :virtualAddress
  uint32   :sizeOfRawData
  uint32   :pointerToRawData
  uint32   :pointerToRelocations
  uint32   :pointerToLinenumbers
  uint16   :numberOfRelocations
  uint16   :numberOfLinenumbers
  uint32   :characteristics
end

class PEFILE < BinData::Record
  endian :little

  IMAGE_DOS_HEADER :dosHeader
  array :dosStub,
    :initial_length => lambda {
      dosHeader.e_lfanew - dosStub.abs_offset
    } do uint8 end

  IMAGE_NT_HEADERS :ntHeaders
  array :sectionHeaders,
    :type => IMAGE_SECTION_HEADER,
    :initial_length => lambda {
      ntHeaders.fileHeader.numberOfSections
    }
end
