%include "nasm-utils-inc.asm"

GLOBAL closure_thunk:function

closure_thunk:

push rsi
push_callee_saved

call rdi

; set up the function name
mov rdi, [rsp + 48]

; now check whether any regs were clobbered
cmp rbp, [rsp + 40]
jne bad_rbp
cmp rbx, [rsp + 32]
jne bad_rbx
cmp r12, [rsp + 24]
jne bad_r12
cmp r13, [rsp + 16]
jne bad_r13
cmp r14, [rsp + 8]
jne bad_r14
cmp r15, [rsp]
jne bad_r15

add rsp, 7 * 8
ret

thunk_boilerplate
