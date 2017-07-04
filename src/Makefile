default:	loader

clean:
	$(RM) loader.lst loader

%.o: %.asm
	nasm -O9 -f elf64 -l $*.lst -o $@ $<

%: %.o
	ld -s -o $@ $<

loader.asm: constants.inc syscall.inc
