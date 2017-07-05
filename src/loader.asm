%include "constants.inc"
%include "syscall.inc"

%macro alignz 1
	align %1, db 0
%endmacro

%macro print 2+
	[section .data]
%%str:	db	%2
%%ptr:	alignz 16
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

section .bss align=16
errno: resq 1

section .data align=16
squashfs: db "squashfs", 0
	alignz 16

nullstring: db 0
	alignz 16

%include "errors.inc"

section .text

__loopback_mount:

	sys_open([rsp + 40], O_CLOEXEC | O_RDONLY, 0)
	cmp	rax,	ENOENT
	jne	.0
	print STDOUT, "Unable to find squashfs file, skipping mount."
	jmp	.skip
.0:	error_check "Unable to open squashfs file!"

	mov	[rsp + 16], rax

	sys_ioctl([loopcontrol], LOOP_CTL_GET_FREE, 0)
	error_check "Unable to allocate loopback device!"

	or	rax,	7 << 8
	mov	[rsp + 8], rax

	sys_mknod([rsp + 32], S_IFBLK | 0600O, [rsp + 8])
	error_check "Unable to create loopback device!"

	sys_open([rsp + 32], O_CLOEXEC | O_RDWR, 0)
	error_check "Unable to open loopback device!"

	mov	[rsp + 8], rax

	sys_ioctl([rsp + 8], LOOP_SET_FD, [rsp + 16])
	error_check "Unable to attach squashfs to loopback device!"

	sys_close([rsp + 16])
	error_check "Unable to close squashfs file!"

	sys_close([rsp + 8])
	error_check "Unable to close loopback device!"

	sys_mount([rsp + 32], [rsp + 24], squashfs, MS_RDONLY, nullstring)
	error_check "Unable to mount /usr!"

	sys_unlink([rsp + 32])
	error_check "Unable to unlink loopback device!"

.skip:
	print STDOUT, 10, 13
	ret



__abort:
	mov	rax,	[errno]
	neg	rax
	shl	rax,	4
	cmp	rax,	errors.max
	jae	.unknown
	mov	rbx,	[errors + rax]
	cmp	rbx,	0
	je	.unknown
	sys_write(STDERR, rbx, [errors + rax + 8])
	jmp	_exit_error

.unknown:
	mov	rax,	[errno]
	mov	ecx,	16
.0:	mov	rdx,	rax
	shr	rax,	4
	and	edx,	15
	mov	dl,	[hex + edx]
	mov	[error_buffer.hex + rcx - 1], dl
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
	error_check "Unable to open loop-control device!"

	mov	[loopcontrol], rax

	sys_unlink(loopcontrolfilename)
	error_check "Unable to unlink loop-control device!"

	[section .data]
usrsquashfsfilename: db "srv/read-only/usr.squashfs", 0
	alignz 16

usrloopdevfilename: db "loop-usr", 0
	alignz 16

usrmountpoint: db "usr", 0
	alignz 16
	__SECT__

_usr:
	print STDOUT, "Mounting /usr..."

	push	usrsquashfsfilename	; rsp + 40
	push	usrloopdevfilename	; rsp + 32
	push	usrmountpoint		; rsp + 24
	push	QWORD 0			; rsp + 16
	push	QWORD 0			; rsp +  8
	call	__loopback_mount
	add	rsp,	40



	[section .data]
lib64squashfsfilename: db "srv/read-only/lib64.squashfs", 0
	alignz 16

lib64loopdevfilename: db "loop-lib64", 0
	alignz 16

lib64mountpoint: db "lib64/", 0
	alignz 16
	__SECT__

_lib64:
	print STDOUT, "Mounting /lib64..."

	push	lib64squashfsfilename	; rsp + 40
	push	lib64loopdevfilename	; rsp + 32
	push	lib64mountpoint		; rsp + 24
	push	QWORD 0			; rsp + 16
	push	QWORD 0			; rsp +  8
	call	__loopback_mount
	add	rsp,	40



	[section .data]
hiddensquashfsfilename: db "srv/read-only/hidden.squashfs", 0
	alignz 16

hiddenloopdevfilename: db "loop-hidden", 0
	alignz 16

hiddenmountpoint: db "srv/read-only", 0
	alignz 16
	__SECT__

_hidden:
	print STDOUT, "Hiding /srv/read-only..."

	push	hiddensquashfsfilename	; rsp + 40
	push	hiddenloopdevfilename	; rsp + 32
	push	hiddenmountpoint	; rsp + 24
	push	QWORD 0			; rsp + 16
	push	QWORD 0			; rsp +  8
	call	__loopback_mount
	add	rsp,	40



_execve:

	[section .data]
execve_filename: db "sbin/init", 0
	alignz 16

argv_init: db "init", 0
	alignz 16

argv:	dq argv_init, 0
	alignz 16

env_home: db "HOME=/", 0
	alignz 16

env_term: db "TERM=linux", 0
	alignz 16

env:	dq env_home, env_term, 0
	alignz 16
	__SECT__

	sys_execve(execve_filename, argv, env)
	error_check "Unable to transfer control to /sbin/init via execve!"

	sys_exit(2)
