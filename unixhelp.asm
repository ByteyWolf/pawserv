section .data
crtbreak dd 0
allocbreak dd 0

section .text
global meminit
global alloc
global free

meminit:
    mov eax, 45
    xor ebx, ebx
    int 0x80
    mov [crtbreak], eax
    mov [allocbreak], eax
    ret

; pass size in ebx, returns ptr in eax, actual allocated size in ebx
alloc:
    ; align memory to 4 bytes
    add ebx, 3
    and ebx, 0xFFFFFFFC
    push ebx
    
    ; check if crtbreak + requested > actual heap
    mov eax, [crtbreak]
    add ebx, eax
    cmp ebx, [allocbreak]
    ja .moveup
    
    ; our request fits in existing heap
    mov eax, [crtbreak]
    mov [crtbreak], ebx
    pop ebx
    ret

    .moveup:
    ; move break up to new bound
    mov eax, 45
    ; ebx already contains new break address
    int 0x80
    
    ; check if syscall succeeded
    cmp eax, 0
    jl .failure
    
    mov [allocbreak], eax
    
    ; check result
    pop ebx
    mov eax, [crtbreak]
    add ebx, eax
    cmp ebx, [allocbreak]
    ja .failure
    
    mov eax, [crtbreak]
    mov [crtbreak], ebx
    sub ebx, eax
    ret

    .failure:
    xor eax, eax
    xor ebx, ebx
    ret

; pass size in ebx
free:
    sub [crtbreak], ebx
    ret