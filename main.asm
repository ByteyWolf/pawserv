section .bss
    filebuf: RESB 4096

section .data
    teststr db "/te%73t/.h./..\./f%6F%6F/.././b.ar/..hidden/./.../fi%6C%65/pa%74h/..%2Fnot-actually-up/./here.we/are..."
    teststrlen equ $ - teststr
    nl db 10

    err_illegal db "ERROR: That path is illegal!", 10
    err_illegal_len equ $ - err_illegal

section .text

extern malloc
extern free

extern hex2string
extern path2stack

extern openconfig

extern srvrootstr
extern bashrootstr
extern srv_anonymous
extern srv_logaccess

extern strlen

global _start
global die

global filebuf

_start:
    call openconfig

    mov eax, [srvrootstr]
    call strlen

    mov edx, eax
    mov ecx, [srvrootstr]
    mov ebx, 1
    mov eax, 4
    int 0x80
    call newline

    mov eax, teststr
    mov ebx, teststrlen
    call hex2string

    push eax
    push ebx
    mov edx, ebx
    mov ecx, eax
    mov ebx, 1
    mov eax, 4
    int 0x80
    call newline
    call newline
    pop ebx
    pop eax
    
    call path2stack

    cmp eax, 0xFFFFFFFF
    je .failpath

    mov edx, eax
    imul edx, 8
    mov esi, esp
    add esi, edx

.print:
    cmp eax, 0
    je die
    mov ebx, [esi-8]
    mov ecx, [esi-4]
    sub esi, 8

    push eax
    mov eax, 4
    mov edx, ecx
    mov ecx, ebx
    mov ebx, 1
    int 0x80
    call newline
    pop eax

    dec eax
    jmp .print

.failpath:
    mov eax, 4
    mov ebx, 1
    mov ecx, err_illegal
    mov edx, err_illegal_len
    int 0x80
    jmp die



newline:
    mov edx, 1
    mov ecx, nl
    mov ebx, 1
    mov eax, 4
    int 0x80
    ret

die:
    mov eax, 1
    mov ebx, 0
    int 0x80