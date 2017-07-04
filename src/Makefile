default:	loader

clean:
	$(RM) loader.lst loader.o loader

%.o: %.asm
	nasm -O9 -f elf64 -l $*.lst -o $@ $<

%: %.o
	ld -s -o $@ $<

loader.o: constants.inc syscall.inc errors.inc
