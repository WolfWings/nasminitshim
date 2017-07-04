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

_usr:
	[section .data]
usrsquashfsfilename: db "srv/read-only/usr.squashfs", 0
	alignz 16
	__SECT__

	sys_open(usrsquashfsfilename, O_CLOEXEC | O_RDONLY, 0)
	cmp	rax,	ENOENT
	jne	.0
	print STDOUT, "Unable to find squashfs file for /usr, skipping mount."
	jmp	_usr_skip
.0:	error_check "Unable to open squashfs file for /usr!"

	[section .bss]
usrsquashfsfile: resq 1
	__SECT__

	mov	[usrsquashfsfile], rax

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

	sys_mknod(usrloopdevfilename, S_IFBLK | 0600O, [usrloopdev])
	error_check "Unable to create loopback device for /usr!"

	sys_open(usrloopdevfilename, O_CLOEXEC | O_RDWR, 0)
	error_check "Unable to open loopback device for /usr!"

	mov	[usrloopdev], rax

	sys_ioctl([usrloopdev], LOOP_SET_FD, [usrsquashfsfile])
	error_check "Unable to attach squashfs to loopback device for /usr!"

	sys_close([usrsquashfsfile])
	error_check "Unable to close squashfs file for /usr!"

	sys_close([usrloopdev])
	error_check "Unable to close loopback device for /usr!"

	[section .data]
usrmountpoint: db "usr", 0
	alignz 16
	__SECT__

	sys_mount(usrloopdevfilename, usrmountpoint, squashfs, MS_RDONLY, nullstring)
	error_check "Unable to mount /usr!"

	sys_unlink(usrloopdevfilename)
	error_check "Unable to unlink loopback device for /usr!"

_usr_skip:



_lib64:
	[section .data]
lib64squashfsfilename: db "srv/read-only/lib64.squashfs", 0
	alignz 16
	__SECT__

	sys_open(lib64squashfsfilename, O_CLOEXEC | O_RDONLY, 0)
	cmp	rax,	ENOENT
	jne	.0
	print STDOUT, "Unable to find squashfs file for /lib64, skipping mount."
	jmp	_lib64_skip
.0:	error_check "Unable to open squashfs file for /lib64!"

	[section .bss]
lib64squashfsfile: resq 1
	__SECT__

	mov	[lib64squashfsfile], rax

	sys_ioctl([loopcontrol], LOOP_CTL_GET_FREE, 0)
	error_check "Unable to allocate loopback device for /lib64!"

	[section .bss]
lib64loopdev: resq 1
	__SECT__

	or	rax,	7 << 8
	mov	[lib64loopdev], rax

	[section .data]
lib64loopdevfilename: db "loop-lib64", 0
	__SECT__

	sys_mknod(lib64loopdevfilename, S_IFBLK | 0600O, [lib64loopdev])
	error_check "Unable to create loopback device for /lib64!"

	sys_open(lib64loopdevfilename, O_CLOEXEC | O_RDWR, 0)
	error_check "Unable to open loopback device for /lib64!"

	mov	[lib64loopdev], rax

	sys_ioctl([lib64loopdev], LOOP_SET_FD, [lib64squashfsfile])
	error_check "Unable to attach squashfs to loopback device for /lib64!"

	sys_close([lib64squashfsfile])
	error_check "Unable to close squashfs file for /lib64!"

	sys_close([lib64loopdev])
	error_check "Unable to close loopback device for /lib64!"

	[section .data]
lib64mountpoint: db "lib64/", 0
	alignz 16
	__SECT__

	sys_mount(lib64loopdevfilename, lib64mountpoint, squashfs, MS_RDONLY, nullstring)
	error_check "Unable to mount /lib64!"

	sys_unlink(lib64loopdevfilename)
	error_check "Unable to unlink loopback device for /lib64!"

_lib64_skip:



_hidden:
	[section .data]
hiddensquashfsfilename: db "srv/read-only/hidden.squashfs", 0
	alignz 16
	__SECT__

	sys_open(hiddensquashfsfilename, O_CLOEXEC | O_RDONLY, 0)
	cmp	rax,	ENOENT
	jne	.0
	print STDOUT, "Unable to find squashfs file for hiding /srv/read-only, skipping mount."
	jmp	_hidden_skip
.0:	error_check "Unable to open squashfs file for hiding /srv/read-only!"

	[section .bss]
hiddensquashfsfile: resq 1
	__SECT__

	mov	[hiddensquashfsfile], rax

	sys_ioctl([loopcontrol], LOOP_CTL_GET_FREE, 0)
	error_check "Unable to allocate loopback device for hiding /srv/read-only!"

	[section .bss]
hiddenloopdev: resq 1
	__SECT__

	or	rax,	7 << 8
	mov	[hiddenloopdev], rax

	[section .data]
hiddenloopdevfilename: db "loop-hidden", 0
	__SECT__

	sys_mknod(hiddenloopdevfilename, S_IFBLK | 0600O, [hiddenloopdev])
	error_check "Unable to create loopback device for hiding /srv/read-only!"

	sys_open(hiddenloopdevfilename, O_CLOEXEC | O_RDWR, 0)
	error_check "Unable to open loopback device for hiding /srv/read-only!"

	mov	[hiddenloopdev], rax

	sys_ioctl([hiddenloopdev], LOOP_SET_FD, [hiddensquashfsfile])
	error_check "Unable to attach squashfs to loopback device for hiding /srv/read-only!"

	sys_close([hiddensquashfsfile])
	error_check "Unable to close squashfs file for hiding /srv/read-only!"

	sys_close([hiddenloopdev])
	error_check "Unable to close loopback device for hiding /srv/read-only!"

	[section .data]
hiddenmountpoint: db "srv/read-only", 0
	alignz 16
	__SECT__

	sys_mount(hiddenloopdevfilename, hiddenmountpoint, squashfs, MS_RDONLY, nullstring)
	error_check "Unable to apply mount to hide /srv/read-only!"

	sys_unlink(hiddenloopdevfilename)
	error_check "Unable to unlink loopback device for hiding /srv/read-only!"

_hidden_skip:



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
