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
        if ((ret = test_simple()) != MAGIC_RETURN) {
            printf("BAD ret:\nret:      %zu\nexpected: %zu\n", ret, MAGIC_RETURN);
            die("good_asm didn't return MAGIC_RETURN");
        }

        // test that a function that clobbers all caller saved regs works
        if ((ret = test_clobber_ok()) != MAGIC_RETURN) {
            printf("BAD ret:\nret:      %zu\nexpected: %zu\n", ret, MAGIC_RETURN);
            die("good_asm didn't return MAGIC_RETURN");
        }

        printf("PASSED: test_good\n");
    } else {
        // it's one of the register testcases

#define TESTCASE(REG) \
        else if (strcmp(testcase, #REG) == 0) { \
            test_clobber_ ## REG (); \
            /* the above line should terminate the process (the test script will test the output for the correct output)*/ \
            printf("FAILURE: clobbering of register %s wasn't detected\n", #REG); \
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
