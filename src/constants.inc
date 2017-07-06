section .bss align=16
section .data align=16
section .text align=16

%macro alignz 1
	align %1, db 0
%endmacro


%macro print 2+
	[section .data]
	alignz 16
%%str:	db	%2
%%ptr:
	__SECT__

	sys_write(%1, %%str, %%ptr - %%str)
%endmacro

STDIN			EQU 0
STDOUT			EQU 1
STDERR			EQU 2

O_RDONLY		EQU 0
O_WRONLY		EQU 1
O_RDWR			EQU 2

O_CLOEXEC		EQU 02000000O

S_IFSOCK		EQU 0140000O
S_IFLNK			EQU 0120000O
S_IFREG			EQU 0100000O
S_IFBLK			EQU 0060000O
S_IFDIR			EQU 0040000O
S_IFCHR			EQU 0020000O
S_IFIFO			EQU 0010000O
S_ISUID			EQU 0004000O
S_ISGID			EQU 0002000O
S_ISVTX			EQU 0001000O

LOOP_SET_FD		EQU 0x4C00

LOOP_CTL_GET_FREE	EQU 0x4C82

ENOENT			EQU -2

MS_RDONLY		EQU 1
