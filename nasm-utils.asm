%include "nasm-utils-inc.asm"

GLOBAL closure_thunk:function

closure_thunk:

push_callee_saved
push rsi

call rdi

; set up the function name
pop rdi

; now check whether any regs were clobbered
cmp rbx, [rsp + 40]
jne bad_rbx
cmp r12, [rsp + 32]
jne bad_r12
cmp r13, [rsp + 24]
jne bad_r13
cmp r14, [rsp + 16]
jne bad_r14
cmp r15, [rsp +  8]
jne bad_r15
cmp rbp, [rsp +  0]
jne bad_rbp

add rsp, 6 * 8
ret

thunk_boilerplate
