ASM := $(wildcard *.asm)

all: $(ASM:%.asm=%.bin)
%.bin: %_asm.o %_c.o
	gcc -m32 -g -Wall -o $@ $^
%_asm.o: %.asm macros.mac
	nasm -f elf $< -o $@
%_c.o: %.c
	gcc -m32 -c -g -Wall -o $@ $^

macros.mac: /usr/include/asm/unistd_32.h
	@rm -f $@
	@echo '%ifndef MACROS_MAC' >> $@
	@echo '%define MACROS_MAC' >> $@
	@echo >> $@
	@awk '$$1~/define/{printf("%%define SYSCALL_%s %d\n",toupper(substr($$2,6)),$$3)}' $< >> $@
	@echo >> $@
	@echo '%endif' >> $@

asmexec: asmexec.o
	ld -melf_i386 -s -o $@ $<

clean:
	@rm -f macros.mac *.o main
