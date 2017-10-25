# rebuild when makefile changes
-include dummy.rebuild

ASSEMBLER := nasm
#AFLAGS := -g -Fdwarf -w+all -l test-funcs.list
AFLAGS := -w+all -l test-funcs.list
CFLAGS := -O0 -g -Wall -Wextra

OBJECTS := $(SRC_FILES:.c=.o) x86_methods.o

.PHONY = all

###########
# Targets #
###########

all: test

test: test-funcs.o test.o nasm-utils-helper.o 

test-funcs.o: test-funcs.asm nasm-util-inc.asm
	$(ASSEMBLER) -f elf64 $(AFLAGS) test-funcs.asm
	
run-tests: test
	@./test good
	@./test-reg.sh rbp
	@./test-reg.sh rbx
	@./test-reg.sh r12
	@./test-reg.sh r13
	@./test-reg.sh r14
	@./test-reg.sh r15
	@echo "ALL TESTS PASSED"

clean:
	rm -f test *.o *.list
	
# https://stackoverflow.com/a/3892826/149138
dummy.rebuild: Makefile
	touch $@
	$(MAKE) -s clean
