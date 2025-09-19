# This Makefile conditionally compiles and links platform-specific assembly.

# Get the operating system name
UNAME := $(shell uname)

# Compiler and Assembler
CC = gcc
ASM = nasm

# Compiler and Assembler flags
ASMFLAGS = -f elf64
CFLAGS = -fPIE

# Default to Linux objects, and then check if we are on Redox.
OBJS = main.o libc_test_linux.o libc_test_v2_linux.o
TARGET_ASM = libc_test_linux.o libc_test_v2_linux.o

# If the OS is Redox, switch to the Redox-specific configuration.
ifeq ($(UNAME), Redox)
    CFLAGS += -D__redox__
    OBJS = main.o libc_test_redox.o libc_test_v2_redox.o
    TARGET_ASM = libc_test_redox.o libc_test_v2_redox.o
endif

# Target executable name
TARGET = libc_test

# Default target: builds the executable
all: $(TARGET)

# Rule to link the final executable
$(TARGET): $(OBJS)
	$(CC) -no-pie -o $(TARGET) $(OBJS)

# Rule to compile the C source file
main.o: main.c
	$(CC) $(CFLAGS) -c main.c

# Rule to assemble the Linux ASM source
libc_test_linux.o: libc_test_linux.asm
	$(ASM) $(ASMFLAGS) -o libc_test_linux.o libc_test_linux.asm

# Rule to assemble the Redox ASM source
libc_test_redox.o: libc_test_redox.asm
	$(ASM) $(ASMFLAGS) -o libc_test_redox.o libc_test_redox.asm

# Rule to assemble the v2 Linux ASM source
libc_test_v2_linux.o: libc_test_v2_linux.asm
	$(ASM) $(ASMFLAGS) -o libc_test_v2_linux.o libc_test_v2_linux.asm

# Rule to assemble the v2 Redox ASM source
libc_test_v2_redox.o: libc_test_v2_redox.asm
	$(ASM) $(ASMFLAGS) -o libc_test_v2_redox.o libc_test_v2_redox.asm


# Rule to clean up build files
clean:
	rm -f $(TARGET) *.o

# Rule to run the executable for the current platform
run: all
	./$(TARGET)
