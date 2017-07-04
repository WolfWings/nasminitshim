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

section .data align=16
tempdevice:
.ptr:	db	"/tempdevice", 0
.len:	EQU $-.ptr
	alignz	16

error_buffer:
.ptr:	db	"Error 000", 10, 13
.len:	EQU $-.ptr
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
	mov	rax,	[errno]
	neg	rax
	mov	dl,	10
	div	dl
	add	ah,	"0"
	mov	[error_buffer + 8], ah
	mov	ah,	0
	div	dl
	add	ax,	"00"
	mov	[error_buffer + 7], ah
	mov	[error_buffer + 6], al

	sys_write(STDOUT, error_buffer, error_buffer.len)
	sys_exit(1)

	global _start:function
_start:
	print STDOUT, "PocketInit", 10, 13

	[section .data]
loopcontrolfilename: db "/loop-control", 0
	__SECT__

	[section .bss]
loopcontrol: resq 1
	__SECT__

	sys_mknod(loopcontrolfilename, S_IFCHR | 0x600, makedev(10, 237))
	error_check "Unable to create loop-control device!"

	sys_open(loopcontrolfilename, O_CLOEXEC | O_RDWR, 0)
	mov	[loopcontrol], rax
	error_check "Unable to open loop-control device!"

	sys_unlink(loopcontrolfilename)
	error_check "Unable to unlink loop-control device!"

	sys_ioctl([loopcontrol], LOOP_CTL_GET_FREE, 0)
	error_check "Unable to allocate loopback device for /usr!"

	[section .bss]
usrloopdev: resq 1
	__SECT__

	or	rax,	7 << 8
	mov	[usrloopdev], rax

	[section .data]
usrloopdevfilename: db "/loop-usr", 0
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

	sys_unlink(usrloopdevfilename)
	error_check "Unable to unlink loopback device for /usr!"

	sys_exit(0)
