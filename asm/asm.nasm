%include "macros.mac"

global _asmsum

section .data
    hello:     db 'Hello world!',10    ; 'Hello world!' plus a linefeed character
    helloLen:  equ $-hello             ; Length of the 'Hello world!' string
                                       ; (I'll explain soon)
;section .text
;    global _start

;_start:
;    jmp hello_world

hello_world:
    mov ecx,hello         ; Put the offset of hello in ecx
    mov edx,helloLen      ; helloLen is a constant, so we don't need to say
                          ; mov edx,[helloLen] to get it's actual value
    call stdout_write
    jmp exit

_asmsum:
    push    ebp             ; create stack frame
    mov     ebp, esp
    mov     eax, [ebp+8]    ; grab the first argument
    mov     ecx, [ebp+12]   ; grab the second argument
    add     eax, ecx        ; sum the arguments
    pop     ebp             ; restore the base pointer
    ret

stdout_write:
    mov eax,SYSCALL_WRITE ; The system call for write (sys_write)
    mov ebx,1             ; File descriptor 1 - standard output
    int 80h               ; Call the kernel
    ret

exit:
    mov eax,SYSCALL_EXIT  ; The system call for exit (sys_exit)
    mov ebx,0             ; Exit with return code of 0 (no error)
    int 80h
