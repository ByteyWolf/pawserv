section text
extern meminit
extern alloc
extern free
global _start

_start:
    call meminit
    ; try to alloc 15 bytes
    mov ebx, 15
    call alloc
    ; try to alloc 7 bytes
    mov ebx, 7
    call alloc
    ; try to free 7 bytes
    mov ebx, 7
    call free
    ; try to alloc 4 bytes
    mov ebx, 4
    call alloc
    ; try to alloc 3 bytes
    mov ebx, 3
    call alloc
