/*
 * C helper functions that might be useful when interacting with asm code.
 *
 * nasm-utils.h
 */

#ifndef NASM_UTILS_H_
#define NASM_UTILS_H_

#ifndef DISABLE_C_ABI_CHECK

#define CALL_THUNKED_RET(RET, FN, ARGS) \
{\
    typedef typeof(FN ARGS) ret_type; \
                                          \
    ret_type closure() {              \
        return FN ARGS;         \
    }                                 \
    typedef ret_type (*typed_closure)(void);  \
    typedef ret_type (*thunk_t)(typed_closure, const char *); \
\
    thunk_t thunk = (thunk_t)closure_thunk; \
    RET = thunk(&closure, #FN); \
}

#define CALL_THUNKED_VOID(FN, ARGS) \
{\
    typedef typeof(FN ARGS) ret_type; \
                                          \
        ret_type closure() {              \
            return FN ARGS;         \
        }                                 \
        typedef ret_type (*typed_closure)(void);  \
        typedef ret_type (*thunk_t)(typed_closure, const char *); \
\
        thunk_t thunk = (thunk_t)closure_thunk; \
        thunk(&closure, #FN); \
}

void* closure_thunk(void (*)(void));

#else

// ABI checking disabled, make a direct call
#define CALL_THUNKED_RET(RET, FN, ARGS) RET = FN ARGS;
#define CALL_THUNKED_VOID(FN, ARGS)           FN ARGS;

#endif

#endif /* NASM_UTILS_H_ */
