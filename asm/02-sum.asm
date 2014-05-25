global sum

sum:
    push    ebp             ; create stack frame
    mov     ebp, esp
    mov     eax, [ebp+8]    ; grab the first argument
    mov     ecx, [ebp+12]   ; grab the second argument
    add     eax, ecx        ; sum the arguments
    pop     ebp             ; restore the base pointer
    ret
