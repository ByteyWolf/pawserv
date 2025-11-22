section .data
teststr db "Hello%20World%21This%3Ais%3Aa%25test%0AEnd%2e", 10, 0
teststrlen equ $ - teststr

section .text

extern malloc
extern free
extern hex2string

global _start

_start:
    ; try hex2string
    mov eax, teststr
    mov ebx, teststrlen
    call hex2string

    
    ; write it
    mov edx, ebx
    mov ecx, eax
    mov ebx, 1
    mov eax, 4
    int 0x80

    ; die
    mov eax, 1
    mov ebx, 0
    int 0x80
