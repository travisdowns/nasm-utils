#!/bin/bash

# don't generate cores for the crashes below
ulimit -c 0

# test if clobbering the reg given on the command line is detected
# pass one of rbp, rbx, r12, r13, r14, r15

OUT=$(./test $1 2>&1)
EXPECTED="FATAL: function test_clobber_$1 clobbered callee-saved register $1"

if [ "$OUT" == "$EXPECTED" ]; then
	echo "PASSED: test_clobber_$1"
else
	echo "FAILED: test_clobber_$1"
	echo "EXPECTED: $EXPECTED"
	echo "ACTUAL  : $OUT"
	exit 1
fi

