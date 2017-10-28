/*
 * test.c
 */
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <err.h>
#include <string.h>

#define MAGIC_RETURN ((uint64_t)1912673297)

int64_t test_simple(void);
int64_t test_clobber_ok(void);
int64_t test_clobber_rbp(void);
int64_t test_clobber_rbx(void);
int64_t test_clobber_r12(void);
int64_t test_clobber_r13(void);
int64_t test_clobber_r14(void);
int64_t test_clobber_r15(void);

#ifdef USE_C_THUNK
// test the generic C thunk which can wrap most C functions in code that calls a generic thunk
#include "nasm-utils.h"

#define CALL_FUNCTION_RET   CALL_THUNKED_RET
#define CALL_FUNCTION_VOID  CALL_THUNKED_VOID

#else
// defines to test the asm version of the thunk
// that thunk is implemented purely in the asm surrounding the function, so it is transparent at
// compile-time to the C code
#define CALL_FUNCTION_RET(RET, F, ARGS) RET = F ARGS;
#define CALL_FUNCTION_VOID(F, ARGS) F ARGS;
#endif

void die(const char *msg) {
    printf("FAILURE: %s\n", msg);
    exit(EXIT_FAILURE);
}


int main(int argc, char **argv) {

    if (argc != 2) {
        errx(1, "Call test as 'test <testcase>' where testcase is one of good, rbx, rbp, r12, r13, r14 or r15");
    }

    char *testcase = argv[1];
    if (strcmp(testcase, "good") == 0) {
        uint64_t ret;

        // test that a basic function that just returns immediately works
        CALL_FUNCTION_RET(ret, test_simple, ());
        if (ret != MAGIC_RETURN) {
            printf("BAD ret:\nret:      %zu\nexpected: %zu\n", ret, MAGIC_RETURN);
            die("good_asm didn't return MAGIC_RETURN");
        }

        // test that a function that clobbers all caller saved regs works
        CALL_FUNCTION_RET(ret, test_clobber_ok, ());
        if (ret != MAGIC_RETURN) {
            printf("BAD ret:\nret:      %zu\nexpected: %zu\n", ret, MAGIC_RETURN);
            die("good_asm didn't return MAGIC_RETURN");
        }

        printf("PASSED: test_good\n");
    } else {
        // it's one of the register testcases

#define TESTCASE(REG) \
        else if (strcmp(testcase, #REG) == 0) { \
            CALL_FUNCTION_VOID(test_clobber_ ## REG, ())\
            asm volatile ("" ::: "rbp", "rbx", "r12", "r13", "r14", "r15", "memory"); \
            /* the above line should terminate the process (the test script will test the output for the correct output)*/ \
            printf("CLOBBER NOT DETECTED %s\n", #REG); \
            exit(EXIT_FAILURE); \
        }

        if (0) {
        }
        TESTCASE(rbp)
        TESTCASE(rbx)
        TESTCASE(r12)
        TESTCASE(r13)
        TESTCASE(r14)
        TESTCASE(r15)

        else {
            errx(1, "unknown test case: %s", testcase);
        }
    }

    return 0;
}
