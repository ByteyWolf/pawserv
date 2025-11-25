section .text

global strlen

strlen:
    ; eax - str, ebx - len
    xor ebx, ebx
    .charloop:
        mov ecx, [eax+ebx]
        cmp ecx, 0
        je .done
        inc ebx
    .done:
        ret