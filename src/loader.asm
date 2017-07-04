%include "constants.inc"
%include "syscall.inc"

%macro alignz 1
	align %1, db 0
%endmacro

%define makedev(major, minor) ((minor & 0xff) | ((major & 0xfff) << 8) | ((minor & ~0xff) << 12) | ((major & ~0xfff) << 32))

; dev_t, type, readwrite, fd
%macro get_device 4
	sys_mknod(tempdevice, %2 | 0x600, %1)
	cmp	rax,	0
	jl	%%skip

	sys_open(tempdevice, O_CLOEXEC | %3, 0)
	cmp	rax,	0
	jl	%%skip

	mov	[%4],	rax

	sys_unlink(tempdevice)
%%skip:
%endmacro

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

	[section .bss]
loopcontrol: resq 1
	__SECT__

	get_device makedev(10, 237), S_IFCHR, O_RDWR, loopcontrol

	error_check "Unable to open loop-control device!"

	sys_ioctl([loopcontrol], LOOP_CTL_GET_FREE, 0)

	error_check "Unable to allocate loopback device!"

	[section .bss]
usrloopdev: resq 1
	__SECT__

	or	rax,	7 << 8
	mov	[usrloopdev], rax

	get_device [usrloopdev], S_IFBLK, O_RDWR, usrloopdev

	error_check "Unable to open loopback device for /usr!"

	[section .data]
usrloopfilename: db "srv/usr.squashfs", 0
	alignz	16
	__SECT__

	sys_open(usrloopfilename, O_CLOEXEC | O_RDWR, 0)

	error_check "Unable to open squashfs file for /usr!"

	[section .bss]
usrloopfile: resq 1
	__SECT__

	mov	[usrloopfile], rax

	sys_ioctl([usrloopdev], LOOP_SET_FD, [usrloopfile])

	error_check "Unable to attach squashfs to loopback device for /usr!"

	sys_exit(0)
