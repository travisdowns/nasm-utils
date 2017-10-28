# rebuild when makefile changes
-include dummy.rebuild

ASSEMBLER := nasm
#AFLAGS := -g -Fdwarf -w+all -l test-funcs.list
AFLAGS := -w+all
CFLAGS := -Og -g -Wall -Wextra

OBJECTS := $(SRC_FILES:.c=.o) x86_methods.o

ALL_REGS := rbp rbx r12 r13 r14 r15

.PHONY = all test test-asm test-c

###########
# Targets #
###########

all: test

SHARED_TEST_OBJS := nasm-utils-helper.o
ASM_TEST_OBJS    := test-main.o $(SHARED_TEST_OBJS)
C_TEST_OBJS      := test-funcs-disabled.o nasm-utils.o $(SHARED_TEST_OBJS)

test-enabled-asm: test-funcs-enabled.o $(ASM_TEST_OBJS)
	$(CC) $^ -o $@
	
test-disabled-asm: test-funcs-disabled.o $(ASM_TEST_OBJS)
	$(CC) $^ -o $@
	
test-enabled-c: test-main-c-enabled.o $(C_TEST_OBJS)
	$(CC) $^ -o $@
	
test-disabled-c: test-main-c-disabled.o $(C_TEST_OBJS)
	$(CC) $^ -o $@
	

%.o : %.asm test-funcs.asm nasm-utils-inc.asm
	$(ASSEMBLER) -f elf64 $(AFLAGS) $<
	
%-enabled.o : %.asm test-funcs.asm nasm-utils-inc.asm
	$(ASSEMBLER) -f elf64 $(AFLAGS) -DNASM_ENABLE_DEBUG=1 $< -o $@
	
%-disabled.o : %.asm test-funcs.asm nasm-utils-inc.asm
	$(ASSEMBLER) -f elf64 $(AFLAGS) -DNASM_ENABLE_DEBUG=0 $< -o $@


%.o : %.c nasm-utils.h
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $<
	
test-main-c-enabled.o : test-main.c nasm-utils.h
	$(CC) -c $(CPPFLAGS) $(CFLAGS) -DUSE_C_THUNK $< -o $@ 

test-main-c-disabled.o : test-main.c nasm-utils.h
	$(CC) -c $(CPPFLAGS) $(CFLAGS) -DUSE_C_THUNK -DDISABLE_C_ABI_CHECK $< -o $@
	
	
test: test-asm test-c
	@./test-enabled-c good
	@./test-reg.sh enabled-c $(ALL_REGS)
	@./test-reg.sh disabled-c $(ALL_REGS)
	@echo "ALL C TESTS PASSED"

test-asm: test-enabled-asm test-disabled-asm
	@./test-enabled-asm good
	@./test-reg.sh enabled-asm $(ALL_REGS)
	@./test-reg.sh disabled-asm $(ALL_REGS)
	@echo "ALL ASM TESTS PASSED"
	
test-c: test-enabled-c test-disabled-c


clean:
	rm -f test-enabled *.o *.list
	
# https://stackoverflow.com/a/3892826/149138
dummy.rebuild: Makefile
	touch $@
	$(MAKE) -s clean
