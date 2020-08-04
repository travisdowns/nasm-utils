#!/bin/bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
	echo -e "Usage:\n\ttest-reg.sh [enabled-asm|disabled-asm|enabled-c|disabled-c] [rbp|rbx|r12|r13|r14|r15]"
	exit 1
fi

# don't generate cores for the crashes below
ulimit -c 0


if ! [[ "$1" =~ ^(enabled|disabled)-(asm|c)$ ]]; then
	echo "test should be one of enabled-asm, disabled-asm, enabled-c, disabled-c"
	exit 1
fi

binary=test-$1

for reg in "${@:2}"; do
	# test if clobbering the reg given on the command line is detected
	# pass one of rbp, rbx, r12, r13, r14, r15
	if [[ "$1" == enabled* ]]; then
		set +e
		OUT=$(./$binary $reg 2>&1)
		set -e
		EXPECTED="FATAL: function test_clobber_$reg clobbered callee-saved register $reg"

		if [ "$OUT" == "$EXPECTED" ]; then
			echo "PASSED: test_enabled_clobber_$reg"
		else
			echo "FAILED: test_enabled_clobber_$reg"
			echo "EXPECTED: $EXPECTED"
			echo "ACTUAL  : $OUT"
			exit 1
		fi
	elif [[ "$1" == disabled* ]]; then
		set +e
		OUT=$(./$binary $reg 2>&1)
		set -e
		EXPECTED="CLOBBER NOT DETECTED $reg"

		if [ "$OUT" == "$EXPECTED" ]; then
			echo "PASSED: test_disabled_clobber_$reg"
		else
			echo "FAILED: test_disabled_clobber_$reg"
			echo "EXPECTED: $EXPECTED"
			echo "ACTUAL  : $OUT"
			exit 1
		fi
	else
		echo "impossible"
		exit 1
	fi
done

