; Declare external libc functions that we will be using.
extern write
extern stat
extern open
extern read
extern close
extern printf

section .data
    ; Predefined strings and messages for output.
    hello_msg db "Hello from Linux assembly!", 10
    hello_len equ $ - hello_msg

    root_path db "/", 0             ; Path for the stat call, null-terminated.
    stat_ok_msg db "stat call for '/' successful.", 10
    stat_ok_len equ $ - stat_ok_msg
    stat_fail_msg db "stat call for '/' failed.", 10
    stat_fail_len equ $ - stat_fail_msg
    mtime_msg db "'/' modification time (Unix timestamp): %lu", 10, 0 ; Format for printf

    urandom_path db "/dev/urandom", 0 ; Path to the random number generator device file.
    urandom_open_fail_msg db "Failed to open /dev/urandom", 10
    urandom_open_fail_len equ $ - urandom_open_fail_msg
    urandom_read_fail_msg db "Failed to read from /dev/urandom", 10
    urandom_read_fail_len equ $ - urandom_read_fail_msg
    random_num_msg db "Random number: %lu", 10, 0 ; Format string for printf.

section .bss
    ; Buffer to store the stat structure.
    stat_buf resb 144

    ; Buffer to store the random number.
    random_buf resb 8

section .text
    global main_asm_linux

; Entry point for the Linux-specific assembly code.
main_asm_linux:
    push rbp
    mov rbp, rsp

    ; --- 1. Call write ---
    mov rdi, 1
    mov rsi, hello_msg
    mov rdx, hello_len
    call write

    ; --- 2. Call stat("/") ---
    mov rdi, root_path
    mov rsi, stat_buf
    call stat

    cmp rax, 0
    jne .stat_failed

    ; --- Stat succeeded ---
    mov rdi, 1
    mov rsi, stat_ok_msg
    mov rdx, stat_ok_len
    call write

    ; Now, print the modification time.
    ; stat struct, st_mtim.tv_sec is at offset 88.
    mov rdi, mtime_msg
    mov rsi, [stat_buf + 88] ; Move the 8-byte timestamp into rsi
    mov rax, 0               ; No floating point arguments for printf
    call printf
    jmp .after_stat

.stat_failed:
    ; Stat failed
    mov rdi, 1
    mov rsi, stat_fail_msg
    mov rdx, stat_fail_len
    call write

.after_stat:
    ; --- 3. Get a random number from /dev/urandom ---
    mov rdi, urandom_path
    mov rsi, 0 ; O_RDONLY
    call open

    cmp rax, 0
    jl .urandom_open_failed
    mov r12, rax ; Save the file descriptor

    ; Read from the file
    mov rdi, r12
    mov rsi, random_buf
    mov rdx, 8
    call read

    cmp rax, 8
    jne .urandom_read_failed

    ; Close the file
    mov rdi, r12
    call close

    ; Print the random number
    mov rdi, random_num_msg
    mov rsi, [random_buf]
    mov rax, 0
    call printf
    jmp .done

.urandom_open_failed:
    mov rdi, 1
    mov rsi, urandom_open_fail_msg
    mov rdx, urandom_open_fail_len
    call write
    jmp .done

.urandom_read_failed:
    mov rdi, 1
    mov rsi, urandom_read_fail_msg
    mov rdx, urandom_read_fail_len
    call write
    mov rdi, r12 ; Still try to close the file
    call close

.done:
    mov rsp, rbp
    pop rbp
    ret
