; This assembly file simulates the Go `sysvicall` convention
; for calling various libc functions on Linux.

extern stat
extern printf
extern write
extern open
extern read
extern close

section .data
    ; --- General Messages ---
    section_header db "--- Go-style v2 Test (Linux) ---", 10
    header_len equ $ - section_header

    ; --- Test 1: Write ---
    hello_msg_v2 db "v2 write call successful.", 10
    hello_len_v2 equ $ - hello_msg_v2

    ; --- Test 2: Stat ---
    stat_ok_msg db "v2 stat call successful.", 10
    stat_ok_len equ $ - stat_ok_msg
    stat_fail_msg db "v2 stat call failed.", 10
    stat_fail_len equ $ - stat_fail_msg
    mtime_msg db "'/' modification time (Unix timestamp): %lu", 10, 0
    root_path db "/", 0

    ; --- Test 3: Urandom ---
    urandom_path db "/scheme/rand", 0
    urandom_open_fail_msg db "v2 failed to open /scheme/rand", 10
    urandom_open_fail_len equ $ - urandom_open_fail_msg
    urandom_read_fail_msg db "v2 failed to read from /scheme/rand", 10
    urandom_read_fail_len equ $ - urandom_read_fail_msg
    random_num_msg db "v2 Random number: %lu", 10, 0

section .bss
    stat_buf resb 144
    random_buf resb 8

    ; This is the array of arguments that libcall.args will point to.
    ; Needs to be large enough for the call with the most arguments (3).
    libcall_args resq 3

    ; A representation of Go's `libcall` struct in memory.
    libcall_s resq 3 ; fn, n, args

section .text
    global main_asm_v2_linux

; =========================================================================
; This is our reusable "asmsysvicall6" simulation.
; It expects a pointer to the libcall_s struct in RDI.
; It unpacks the struct, places arguments into the correct registers
; for the System V AMD64 ABI, and calls the target function.
; It currently supports up to 3 arguments.
asmsysvicall6:
    mov rax, [rdi + 0]  ; Get libcall.fn into rax (the function to call)
    mov rcx, [rdi + 8]  ; Get libcall.n (number of arguments)
    mov r11, [rdi + 16] ; Get libcall.args (pointer to argument array)

    ; Load arguments into registers based on count.
    ; ABI: RDI, RSI, RDX, RCX, R8, R9
    cmp rcx, 0
    je .do_call
    mov rdi, [r11 + 0]
    cmp rcx, 1
    je .do_call
    mov rsi, [r11 + 8]
    cmp rcx, 2
    je .do_call
    mov rdx, [r11 + 16]
    ; Extend here for more args if needed.

.do_call:
    call rax  ; Call the actual libc function
    ret
; =========================================================================

; Entry point for the v2 Linux assembly code.
main_asm_v2_linux:
    push rbp
    mov rbp, rsp
    sub rsp, 8 ; Reserve 8 bytes on stack for the file descriptor

    ; --- 0. Print a header for this section ---
    mov rdi, 1
    mov rsi, section_header
    mov rdx, header_len
    call write

    ; --- 1. Test 'write' through the sysvicall simulation ---
    mov qword [libcall_args + 0], 1            ; arg 1: stdout
    mov qword [libcall_args + 8], hello_msg_v2 ; arg 2: message
    mov qword [libcall_args + 16], hello_len_v2; arg 3: length
    mov qword [libcall_s + 0], write           ; fn
    mov qword [libcall_s + 8], 3               ; n
    mov qword [libcall_s + 16], libcall_args   ; args
    mov rdi, libcall_s
    call asmsysvicall6

    ; --- 2. Test 'stat' through the sysvicall simulation ---
    mov qword [libcall_args + 0], root_path ; arg 1: path
    mov qword [libcall_args + 8], stat_buf  ; arg 2: buffer
    mov qword [libcall_s + 0], stat         ; fn
    mov qword [libcall_s + 8], 2            ; n
    mov qword [libcall_s + 16], libcall_args; args
    mov rdi, libcall_s
    call asmsysvicall6
    cmp rax, 0
    jne .stat_failed

    ; Stat succeeded
    mov rdi, 1
    mov rsi, stat_ok_msg
    mov rdx, stat_ok_len
    call write
    mov rdi, mtime_msg
    mov rsi, [stat_buf + 88] ; The timestamp value
    mov rax, 0               ; No floating point args for printf
    call printf
    jmp .after_stat

.stat_failed:
    mov rdi, 1
    mov rsi, stat_fail_msg
    mov rdx, stat_fail_len
    call write
.after_stat:

    ; --- 3. Test 'open', 'read', 'close' for /scheme/rand ---
    ; --- open ---
    mov qword [libcall_args + 0], urandom_path ; arg 1: path
    mov qword [libcall_args + 8], 65536        ; arg 2: O_RDONLY
    mov qword [libcall_s + 0], open            ; fn
    mov qword [libcall_s + 8], 2               ; n
    mov qword [libcall_s + 16], libcall_args   ; args
    mov rdi, libcall_s
    call asmsysvicall6
    cmp rax, 0
    jl .urandom_open_failed
    mov [rbp - 8], rax ; Save file descriptor on the stack

    ; --- read ---
    mov rdi, [rbp - 8]                         ; Get fd for arg 1
    mov qword [libcall_args + 0], rdi
    mov qword [libcall_args + 8], random_buf   ; arg 2: buffer
    mov qword [libcall_args + 16], 8           ; arg 3: count
    mov qword [libcall_s + 0], read            ; fn
    mov qword [libcall_s + 8], 3               ; n
    mov qword [libcall_s + 16], libcall_args   ; args
    mov rdi, libcall_s
    call asmsysvicall6
    cmp rax, 8
    jne .urandom_read_failed

    ; --- printf (for the random number) ---
    mov rsi, [random_buf]                      ; Get random value for arg 2
    mov qword [libcall_args + 0], random_num_msg ; arg 1: format string
    mov qword [libcall_args + 8], rsi
    mov qword [libcall_s + 0], printf          ; fn
    mov qword [libcall_s + 8], 2               ; n
    mov qword [libcall_s + 16], libcall_args   ; args
    mov rdi, libcall_s
    mov rax, 0 ; Clear rax for printf
    call asmsysvicall6
    jmp .urandom_close ; Jump to close the file

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
    ; Fall through to close the file

.urandom_close:
    ; --- close ---
    mov rdi, [rbp - 8] ; get fd for arg 1
    mov qword [libcall_args + 0], rdi
    mov qword [libcall_s + 0], close           ; fn
    mov qword [libcall_s + 8], 1               ; n
    mov qword [libcall_s + 16], libcall_args   ; args
    mov rdi, libcall_s
    call asmsysvicall6

.done:
    add rsp, 8 ; Deallocate stack space
    mov rsp, rbp
    pop rbp
    ret

