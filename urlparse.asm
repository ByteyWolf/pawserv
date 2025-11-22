section .text

global hex2string

; translate hex escapes (%) to normal
hex2string:
    ; eax - pointer to string
    ; ebx - string length
    push eax
    push ebx
    mov edx, eax
    
    .advance:
    mov byte cl, [eax]
    inc eax
    dec ebx

    ; percent?
    cmp cl, '%'
    je .translate

    .append:
    mov byte [edx], cl
    inc edx

    ; is string over?
    cmp ebx, 0
    je .done
    
    jmp .advance

    .translate:
        ;int3
        mov ch, [eax]
        and ch, 0x7F
        mov cl, [eax+1]
        and cl, 0x7F
        
        cmp cl, ':'
        jl .num1digit
        sub cl, 'A'-10
        jmp .conv2
        
        .num1digit:
            sub cl, '0'
        .conv2:
            cmp ch, ':'
            jl .num2digit
            sub ch, 'A'-10
            jmp .merge
        
        .num2digit:
            sub ch, '0'

        .merge:
        ; ch - big, cl - small
        push edx
        mov dl, ch
        shl edx, 4
        mov ch, 0
        or dx, cx
        mov cx, dx
        pop edx

        .transdone:
        sub ebx, 2
        add eax, 2
        jmp .append
        
    .done:
    pop ebx
    sub eax, edx
    sub ebx, eax
    pop eax
    ret