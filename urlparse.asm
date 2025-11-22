section .text

global hex2string
global path2stack

; translate hex escapes (%) to normal
; clobbers ecx, edx
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
        or dl, cl
        mov cl, dl
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

; converts a path into nodes in the stack
path2stack:
    ; eax - pointer to string
    ; ebx - string length
    
    pop edi ; recover target addr
    mov dl, 0 ; nodes created
    mov dh, 0 ; dots encountered (>2 - invalid)
    mov ebp, eax ; last ptr since slash encountered
    xor ecx, ecx

    .advance:
    mov cl, [eax]
    inc eax
    dec ebx

        .slashcheck:
        cmp cl, '/'
        je .addnode
        cmp cl, 0x5C
        je .addnode

        ; is dot?
        cmp dh, 2
        jg .notdot

        cmp cl, '.'
        jne .notdot
        je .dot

        .dot:
        inc dh
        jmp .skipadd

        .notdot:
        mov dh, 3
        jmp .skipadd

    .addnode:
        ; check that we didn't exceed our limit
        cmp dl, 64
        jg .invalid

        ; check for dot patterns
        cmp dh, 2
        je .goup
        cmp dh, 1
        je .updateebp

        ; push new node onto stack
        mov ecx, eax
        sub ecx, ebp
        dec ecx
        
        ; skip if node is empty, otherwise append
        cmp ecx, 0
        je .updateebp

        push ecx
        push ebp
        inc dl
        jmp .updateebp

        .goup:
        cmp dl, 0
        je .invalid
        add esp, 8 ; kill previous entries
        dec dl
        

    .updateebp:
        mov ebp, eax
        mov dh, 0
        
    .skipadd:
    ; is string over?
    cmp ebx, 0
    je .almostdone
    jmp .advance

    .almostdone:
        ; check for leftovers
        inc eax
        mov ecx, eax
        sub ecx, ebp
        cmp ecx, 1
        jg .addnode

    .done:
    xor eax, eax
    mov al, dl
    push edi
    ret

    .invalid:
    mov eax, 0xFFFFFFFF
    push edi
    ret

    ; eax - nodes made