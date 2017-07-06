	
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



%define sys_write(fd, buf, len)			syscall_4 1, fd, buf, len
%define sys_open(filename, flags, mode)		syscall_4 2, filename, flags, mode
%define sys_close(fd)				syscall_2 3, fd
%define sys_ioctl(fd, cmd, arg)			syscall_4 16, fd, cmd, arg
%define sys_execve(filename, argv, env)		syscall_4 59, filename, argv, env
%define sys_exit(code)				syscall_2 60, code
%define sys_rename(old, new)			syscall_3 82, old, new
%define sys_unlink(filename)			syscall_2 87, filename
%define sys_mknod(filename, mode, dev)		syscall_4 133, filename, mode, dev
%define sys_mount(dev, dir, type, flags, data)	syscall_6 165, dev, dir, type, flags, data
