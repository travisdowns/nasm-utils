;; potentially useful macros for asm development

;; push the 6 callee-saved registers defined in the the sysv C ABI
%macro push_callee_saved 0
push rbp
push rbx
push r12
push r13
push r14
push r15
%endmacro

;; pop the 6 callee-saved registers in the order compatible with push_callee_saved
%macro pop_callee_saved 0
push r15
push r14
push r13
push r12
push rbx
push rbp
%endmacro

;; boilerplate needed once when abi_checked_function is used
%macro thunk_boilerplate 0
; this function is defined by the C helper code
EXTERN nasm_util_die_on_reg_clobber

boil1 rbp, 1
boil1 rbx, 2
boil1 r12, 3
boil1 r13, 4
boil1 r14, 5
boil1 r15, 6
%endmacro

;; By default, the "assert-like" features that can be conditionally enabled key off the value of the
;; NDEBUG macro: if it is defined, the slower, more heavily checked paths are enabled, otherwise they
;; are omitted (usually resulting in zero additional cost).
;;
;; If you don't want to rely on NDEBUG can specifically enable or disable the debug mode with the
;; NASM_ENABLE_DEBUG set to 0 (equivalent to NDEBUG set) or 1 (equivalent to NDEBUG not set)
%ifndef NASM_ENABLE_DEBUG
    %ifdef NDEBUG
        %define NASM_ENABLE_DEBUG 0
    %else
        %define NASM_ENABLE_DEBUG 1
    %endif
%elif (NASM_ENABLE_DEBUG != 0) && (NASM_ENABLE_DEBUG != 1)
    %error bad value for 'NASM_ENABLE_DEBUG': should be 0 or 1 but was NASM_ENABLE_DEBUG
%endif




;; This macro supports declaring a "ABI-checked" function in asm
;; An ABI-checked function will checked at each invocation for compliance with the SysV ABI
;; rules about callee saved registers. In particular, from the ABI cocument we have the following:
;;
;;      Registers %rbp, %rbx and %r12 through %r15 “belong” to the calling function
;;      and the called function is required to preserve their values.
;;            (from "System V Application Binary Interface, AMD64 Architecture Processor Supplement")
;;
;;
%macro abi_checked_function 1
GLOBAL %1:function
%1:

%if NASM_ENABLE_DEBUG != 0

;%warning compiling ABI checks

; save all the callee-saved regs
push_callee_saved
call %1_inner

; load the function name (ok to clobber rdi since it's callee-saved)
mov rdi, %1_thunk_fn_name

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

add rsp, 6 * 8
ret

%else ; debug off, just assemble the function as-is without any checks
;%warning compiling without ABI checks
%endif

; here we store strings needed by the failure cases, in the .rodata section
[section .rodata]
%1_thunk_fn_name:
%defstr fname %1
db fname,0

; restore the previous section
__SECT__

%1_inner:
%endmacro;; internal


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IMPLEMENTATION FOLLOWS
;; below you find internal macros needed for the implementation of the above macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;

; generate the stubs for the bad_reg functions called from the check-abi thunk
%macro boil1 2
bad_%1:
; A thunk has determined that a reg was clobbered
; each reg has their own bad_ function which moves the function name (in rdx) into
; rdi and loads a constant indicating which reg was involved and calls a C routine
; that will do the rest (abort the program generall). We follow up with an ud2 in case
; the C routine returns, since this mechanism is not designed for recovery.
mov rsi, %2
; here we set up a stack frame - this gives a meaningful backtrace in any core file produced by the abort
; first we need to pop the saved regs off the stack so the rbp chain is consistent
add rsp, 6 * 8
push rbp
mov  rbp, rsp
call nasm_util_die_on_reg_clobber
ud2
%endmacro




