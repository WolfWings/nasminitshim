%include "constants.inc"
%include "syscall.inc"

%macro alignz 1
	align %1, db 0
%endmacro

%define makedev(major, minor) ((minor & 0xff) | ((major & 0xfff) << 8) | ((minor & ~0xff) << 12) | ((major & ~0xfff) << 32))

%macro print 2+
	[section .data]
%%str:	db	%2
%%ptr:	alignz	16
	__SECT__

	sys_write(%1, %%str, %%ptr - %%str)
%endmacro

%macro error_check 1+
	cmp	rax,	0
	jge	%%skip
	mov	[errno],	rax
	sys_write(STDERR, error_banner, error_banner.len)
	print STDERR, "37m ", %1, " "
	sys_write(STDERR, error_banner, error_banner.len2)
	jmp	__abort
%%skip:
%endmacro

%macro error_print 2+
	cmp	rbx, QWORD %1
	jne	%%skip
	print STDERR, %2, 10, 13
	jmp	_exit_error
%%skip:
%endmacro

section .data align=16
error_buffer:
.ptr:	db	"Unknown Error 0x"
.hex:	db	"0000000000000000", 10, 13
.len:	EQU $-.ptr
	alignz	16

hex:	db	"0123456789ABCDEF"
	alignz	16

error_banner:
.ptr:	db	27, "[31;1m!!!ERROR!!!", 27, "["
.len:	EQU $-.ptr
	db	"0m", 10, 13
.len2:	EQU $-.ptr
	alignz	16

section .bss align=16
errno: resq 1

section .text

__abort:
	mov	rbx,	[errno]
	error_print  -1, "EPERM"
	error_print -17, "EEXIST"

	mov	ecx,	16
.0:	mov	rax,	rbx
	shr	rbx,	4
	and	eax,	15
	mov	al,	[hex + eax]
	mov	[error_buffer.hex + rcx - 1], al
	dec	ecx
	jnz	.0
	sys_write(STDOUT, error_buffer, error_buffer.len)

_exit_error:
	sys_exit(1)

	global _start:function
_start:
	print STDOUT, "PocketInit", 10, 13

	[section .data]
loopcontrolfilename: db "loop-control", 0
	__SECT__

	[section .bss]
loopcontrol: resq 1
	__SECT__

	sys_mknod(loopcontrolfilename, S_IFCHR | 0600O, ((10 << 8) + 237))
	error_check "Unable to create loop-control device!"

	sys_open(loopcontrolfilename, O_CLOEXEC | O_RDWR, 0)
	mov	[loopcontrol], rax
	error_check "Unable to open loop-control device!"

%ifndef DEBUG
	sys_unlink(loopcontrolfilename)
	error_check "Unable to unlink loop-control device!"
%endif

	sys_ioctl([loopcontrol], LOOP_CTL_GET_FREE, 0)
	error_check "Unable to allocate loopback device for /usr!"

	[section .bss]
usrloopdev: resq 1
	__SECT__

	or	rax,	7 << 8
	mov	[usrloopdev], rax

	[section .data]
usrloopdevfilename: db "loop-usr", 0
	__SECT__

	sys_mknod(usrloopdevfilename, S_IFBLK | 0x600, [usrloopdev])
	error_check "Unable to create loopback device for /usr!"

	sys_open(usrloopdevfilename, O_CLOEXEC | O_RDWR, 0)
	error_check "Unable to open loopback device for /usr!"

	mov	[usrloopdev], rax

	[section .data]
usrsquashfsfilename: db "srv/usr.squashfs", 0
	alignz	16
	__SECT__

	sys_open(usrsquashfsfilename, O_CLOEXEC | O_RDWR, 0)
	error_check "Unable to open squashfs file for /usr!"

	[section .bss]
usrsquashfsfile: resq 1
	__SECT__

	mov	[usrsquashfsfile], rax

	sys_ioctl([usrloopdev], LOOP_SET_FD, [usrsquashfsfile])
	error_check "Unable to attach squashfs to loopback device for /usr!"

	sys_close([usrsquashfsfile])
	error_check "Unable to close squashfs file for /usr!"

	sys_close([usrloopdev])
	error_check "Unable to close loopback device for /usr!"

	[section .data]
usrmountpoint: db "usr/", 0
	alignz	16

squashfs: db "squashfs", 0
	alignz	16

nullstring: db 0
	alignz 16
	__SECT__

	sys_mount(usrloopdevfilename, usrmountpoint, squashfs, 0, nullstring)
	error_check "Unable to mount /usr!"

%ifndef DEBUG
	sys_unlink(usrloopdevfilename)
	error_check "Unable to unlink loopback device for /usr!"
%endif

	sys_exit(0)
