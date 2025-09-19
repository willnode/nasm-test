# nasm libc test

This is a test case to make sure calling libc function via nasm x86_64 works. This has 2 level of test, the simple ASM test and Go-style (v2) test.

This is written to isolate and debug page faults found in Go port for Redox.
