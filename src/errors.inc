error_buffer:
.ptr:	db	"Unknown Error 0x"
.hex:	db	"0000000000000000", 10, 13
.len:	EQU $-.ptr
	alignz 16

hex:	db	"0123456789ABCDEF"
	alignz 16

error_banner:
.ptr:	db	27, "[31;1m!!!ERROR!!!", 27, "["
.len:	EQU $-.ptr
	db	"0m", 10, 13
.len2:	EQU $-.ptr
	alignz 16

_error_EPERM:
.ptr:	db	"EPERM - Operation not permitted"
.len:	EQU $-.ptr
	alignz 16

_error_ENOENT:
.ptr:	db	"ENOENT - No such file or directory"
.len:	EQU $-.ptr
	alignz 16

_error_EEXIST:
.ptr:	db	"EEXIST - File already exists"
.len:	EQU $-.ptr
	alignz 16

_error_EINVAL:
.ptr:	db	"EINVAL - Invalid argument"
.len:	EQU $-.ptr
	alignz 16

errors:	dq	0, 0
	dq	_error_EPERM, _error_EPERM.len  ; 1
	dq	_error_ENOENT, _error_EPERM.len ; 2
	dq	0, 0 ; 3
	dq	0, 0 ; 4
	dq	0, 0 ; 5
	dq	0, 0 ; 6
	dq	0, 0 ; 7
	dq	0, 0 ; 8
	dq	0, 0 ; 9
	dq	0, 0 ; 10
	dq	0, 0 ; 11
	dq	0, 0 ; 12
	dq	0, 0 ; 13
	dq	0, 0 ; 14
	dq	0, 0 ; 15
	dq	0, 0 ; 16
	dq	_error_EEXIST, _error_EEXIST.len ; 17
	dq	0, 0 ; 18
	dq	0, 0 ; 19
	dq	0, 0 ; 20
	dq	0, 0 ; 21
	dq	_error_EINVAL, _error_EINVAL.len ; 22
.max:	EQU ($-errors)

	alignz 16
