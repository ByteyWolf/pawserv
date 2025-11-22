section .text
global malloc
global free

malloc:
    ; ebx - size
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    
    mov ecx, ebx
    mov eax, 0x5a
    xor ebx, ebx
    mov edx, 3
    mov esi, 0x22
    xor edi, edi
    xor ebp, ebp
    int 0x80

    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx

    ; eax - addr
    ; ebx - size

free:
    ; eax - addr
    ; ebx - size

    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp

    mov ecx, ebx
    mov ebx, eax
    mov eax, 91
    int 0x80

    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ; eax - 0 on success