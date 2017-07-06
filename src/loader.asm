%include "constants.inc"
%include "syscall.inc"
%include "errors.inc"

section .text

	[section .data]
	alignz 16
squashfs: db "squashfs"
nullstring: db 0
	__SECT__

	; Calling ABI:
	;
	;          * PUSH these parameters onto the stack
	; rsp + 40 * Pointer to SquashFS filename, zero terminated
	; rsp + 32 * Pointer to loopback filename, zero terminated
	; rsp + 24 * Pointer to mountpoint, zero terminated
	; rsp + 16 - RET address
	; rsp +  8 - SquashFS File Handle
	; rsp      - Loopback Device Number
	alignz 16
__loopback_mount:
	sub	rsp,	16
	sys_open([rsp + 40], O_CLOEXEC | O_RDONLY, 0)
	cmp	rax,	ENOENT
	jne	.0
	print STDOUT, "No squashfs, skipping mount."
	jmp	.skip
.0:	error_check "Can't open squashfs!"

	mov	[rsp + 8], rax

	sys_ioctl([loopcontrol], LOOP_CTL_GET_FREE, 0)
	error_check "Can't allocate loopback!"

	or	rax,	7 << 8
	mov	[rsp], rax

	sys_mknod([rsp + 32], S_IFBLK | 0600O, [rsp])
	error_check "Can't create loopback!"

	sys_open([rsp + 32], O_CLOEXEC | O_RDWR, 0)
	error_check "Can't open loopback!"

	mov	[rsp], rax

	sys_ioctl([rsp], LOOP_SET_FD, [rsp + 8])
	error_check "Can't attach squashfs to loopback!"

	sys_close([rsp + 8])
	error_check "Can't close squashfs!"

	sys_close([rsp])
	error_check "Can't close loopback!"

	sys_mount([rsp + 32], [rsp + 24], squashfs, MS_RDONLY, nullstring)
	error_check "Can't mount loopback!"

	sys_unlink([rsp + 32])
	error_check "Can't delete loopback!"

.skip:
	print STDOUT, 10, 13
	add	rsp,	16
	ret



	global _start:function
	alignz 16
_start:
	print STDOUT, "PocketInit", 10, 13

	print STDOUT, "Creating loopback control device..."

	[section .data]
loopcontrolfilename: db "loop-control", 0
	__SECT__

	[section .bss]
loopcontrol: resq 1
	__SECT__

	sys_mknod(loopcontrolfilename, S_IFCHR | 0600O, ((10 << 8) + 237))
	error_check "Unable to create!"

	sys_open(loopcontrolfilename, O_CLOEXEC | O_RDWR, 0)
	error_check "Unable to open!"

	mov	[loopcontrol], rax

	sys_unlink(loopcontrolfilename)
	error_check "Unable to delete!"

	print STDOUT, 10, 13

	[section .data]
usrsquashfsfilenamenew: db "srv/read-only/new-usr.squashfs", 0
	alignz 16

usrsquashfsfilename: db "srv/read-only/usr.squashfs", 0
	alignz 16

usrloopdevfilename: db "loop-usr", 0
	alignz 16

usrmountpoint: db "usr", 0
	alignz 16
	__SECT__

_usr:
	print STDOUT, "Setting up /usr..."

	sys_rename(usrsquashfsfilenamenew, usrsquashfsfilename)
	cmp	rax,	0
	jne	.noupdate
	print STDOUT, "Updated version..."
.noupdate:

	push	usrsquashfsfilename
	push	usrloopdevfilename
	push	usrmountpoint
	call	__loopback_mount
	add	rsp,	24



	[section .data]
lib64squashfsfilenamenew: db "srv/read-only/new-lib64.squashfs", 0
	alignz 16

lib64squashfsfilename: db "srv/read-only/lib64.squashfs", 0
	alignz 16

lib64loopdevfilename: db "loop-lib64", 0
	alignz 16

lib64mountpoint: db "lib64/", 0
	alignz 16
	__SECT__

_lib64:
	print STDOUT, "Setting up /lib64..."

	sys_rename(lib64squashfsfilenamenew, lib64squashfsfilename)
	cmp	rax,	0
	jne	.noupdate
	print STDOUT, "Updated version..."
.noupdate:

	push	lib64squashfsfilename
	push	lib64loopdevfilename
	push	lib64mountpoint
	call	__loopback_mount
	add	rsp,	24



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

	push	hiddensquashfsfilename
	push	hiddenloopdevfilename
	push	hiddenmountpoint
	call	__loopback_mount
	add	rsp,	24



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

	print STDOUT, "Transfering control to /sbin/init via execve...", 10, 13

	sys_execve(execve_filename, argv, env)
	error_check "Can't!"

	sys_exit(2)
