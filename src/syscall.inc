	
%macro syscall_1 1
	mov	rax,	%1
	syscall
%endmacro

%macro syscall_2 2
	mov	rdi,	%2
	syscall_1	%1
%endmacro

%macro syscall_3 3
	mov	rsi,	%3
	syscall_2	%1, %2
%endmacro

%macro syscall_4 4
	mov	rdx,	%4
	syscall_3	%1, %2, %3
%endmacro

%macro syscall_5 5
	mov	r10,	%5
	syscall_4	%1, %2, %3, %4
%endmacro

%macro syscall_6 6
	mov	r8,	%6
	syscall_5	%1, %2, %3, %4, %5
%endmacro

%macro syscall_7 7
	mov	r9,	%7
	syscall_6	%1, %2, %3, %4, %5, %6
%endmacro



%define sys_write(fd, buf, len)				syscall_4   1, fd, buf, len
%define sys_open(filename, flags, mode)			syscall_4   2, filename, flags, mode
%define sys_close(fd)					syscall_2   3, fd
%define sys_mmap(addr, len, prot, flags, fd, off)	syscall_7   9, addr, len, prot, flags, fd, off
%define sys_munmap(addr, len)				syscall_3  11, addr, len
%define sys_ioctl(fd, cmd, arg)				syscall_4  16, fd, cmd, arg
%define sys_execve(filename, argv, env)			syscall_4  59, filename, argv, env
%define sys_exit(code)					syscall_2  60, code
%define sys_fsync(fd)					syscall_2  74, fd
%define sys_chdir(dir)					syscall_2  80, dir
%define sys_rename(old, new)				syscall_3  82, old, new
%define sys_rmdir(pathname)				syscall_2  84, pathname
%define sys_unlink(filename)				syscall_2  87, filename
%define sys_mknod(filename, mode, dev)			syscall_4 133, filename, mode, dev
%define sys_pivot_root(new, old)			syscall_3 155, new, old
%define sys_mount(dev, dir, type, flags, data)		syscall_6 165, dev, dir, type, flags, data
%define sys_finit_module(fd, args, flags)		syscall_4 313, fd, args, flags
