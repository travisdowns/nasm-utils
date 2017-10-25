; test functions for the test process

%include "nasm-util-inc.asm"

default rel

%define MAGIC_RETURN 1912673297

thunk_boilerplate

abi_checked_function test_simple
mov rax, MAGIC_RETURN
ret

; clobber the registers we are allowed to clobber
abi_checked_function test_clobber_ok
inc rcx
inc rdx
inc rsi
inc rdi
inc r8
inc r9
inc r10
inc r11
mov rax, MAGIC_RETURN
ret

; clobber the specified register and return MAGIC_RETURN
%macro clobber1 1
abi_checked_function test_clobber_%1
inc %1
mov rax, MAGIC_RETURN
ret
%endmacro

; test clobbering each registers separately
clobber1 rbp
clobber1 rbx
clobber1 r12
clobber1 r13
clobber1 r14
clobber1 r15

