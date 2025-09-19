#include <stdio.h>

// Declare the external assembly functions for both Linux and Redox.
// The linker will need to find one of these depending on what we build.
#ifdef __redox__
extern void main_asm_redox(void);
#else
extern void main_asm_linux(void);
#endif

int main() {
    // The C preprocessor will now include only one of these function calls
    // in the final compiled code, based on the `__redox__` define.
    #ifdef __redox__
        // Call the Redox-specific assembly function.
        main_asm_redox();
    #else
        // Call the Linux-specific assembly function.
        main_asm_linux();
    #endif

    return 0;
}

