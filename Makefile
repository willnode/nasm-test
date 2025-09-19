# This Makefile conditionally compiles and links platform-specific assembly.

# Compiler and Assembler
CC = gcc
ASM = nasm

# Compiler and Assembler flags
ASMFLAGS = -f elf64
CFLAGS = -fPIE

# Default to Linux objects
OBJS = main.o libc_test_linux.o

# If 'REDOX=1' is passed to make, switch to Redox-specific configuration.
# This defines the '__redox__' macro for the C compiler and changes the
# object file that will be linked.
ifdef REDOX
    CFLAGS += -D__redox__
    OBJS = main.o libc_test_redox.o
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

# Rule to clean up build files
clean:
	rm -f $(TARGET) *.o

# Rule to run the default (Linux) version
run: all
	./$(TARGET)

# A convenience rule to build and run the Redox version
run-redox:
	$(MAKE) clean
	$(MAKE) REDOX=1 run

