section .bss
    keybuf: RESB 64
    valbuf: RESB 1024

section .data
    globalpath db "/etc/pawserv/pawserv.conf", 0
    localpath db "./pawserv.conf", 0
    dot db '.', 0

    srvrootstr dd dot
    bashrootstr dd 0
    srv_anonymous db 0
    srv_logaccess db 1

    err_confnotfound db "ERROR: No pawserv.conf file found!", 10, 0
    err_confnotfound_len equ $ - err_confnotfound
    err_fileio db "ERROR: I/O failure when reading file", 10, 0
    err_fileio_len equ $ - err_fileio

section .text
global openconfig
global srvrootstr
global bashrootstr
global srv_anonymous
global srv_logaccess

extern filebuf

openconfig:
    mov eax, 5
    mov ebx, localpath
    mov ecx, 0
    xor edx, edx
    int 0x80
    cmp eax, 0
    jge .readfile
    
    mov eax, 5
    mov ebx, globalpath
    mov ecx, 0
    xor edx, edx
    int 0x80
    cmp eax, 0
    jge .readfile

    mov eax, 4
    mov ebx, 1
    mov ecx, err_confnotfound
    mov edx, err_confnotfound_len
    int 0x80
    ret

.readfile:
    mov edx, 4096
    mov ecx, filebuf
    mov ebx, eax
    mov eax, 3
    int 0x80
    cmp eax, 0
    jle .ioerror

    mov esi, filebuf
    add eax, esi
    mov [filebuf+4096], eax

.parseloop:
    cmp esi, [filebuf+4096]
    jge .done
    
    mov edi, keybuf
    xor ecx, ecx

.readkey:
    cmp esi, [filebuf+4096]
    jge .done
    movzx edx, byte [esi]
    inc esi
    
    cmp edx, '#'
    je .skipcomment
    cmp edx, '='
    je .readvalue
    cmp edx, 10
    je .parseloop
    cmp edx, ' '
    je .readkey
    
    cmp ecx, 63
    jge .readkey
    mov [edi+ecx], dl
    inc ecx
    jmp .readkey

.skipcomment:
    cmp esi, [filebuf+4096]
    jge .done
    movzx edx, byte [esi]
    inc esi
    cmp edx, 10
    jne .skipcomment
    jmp .parseloop

.readvalue:
    push ecx
    mov edi, valbuf
    xor ecx, ecx

.readvalueloop:
    cmp esi, [filebuf+4096]
    jge .processline
    movzx edx, byte [esi]
    inc esi
    
    cmp edx, 10
    je .processline
    cmp edx, ' '
    jne .addvalchar
    cmp ecx, 0
    je .readvalueloop
    
.addvalchar:
    cmp ecx, 1023
    jge .readvalueloop
    mov [edi+ecx], dl
    inc ecx
    jmp .readvalueloop

.processline:
    pop ebx
    cmp ebx, 0
    je .parseloop
    cmp ecx, 0
    je .parseloop
    
    movzx edx, byte [keybuf]
    
    cmp edx, 'a'
    jne .tryb
    movzx edx, byte [valbuf]
    sub edx, '0'
    mov [srv_anonymous], dl
    jmp .parseloop

.tryb:
    cmp edx, 'b'
    jne .tryl
    mov [bashrootstr], dword valbuf
    jmp .parseloop

.tryl:
    cmp edx, 'l'
    jne .trys
    movzx edx, byte [valbuf]
    sub edx, '0'
    mov [srv_logaccess], dl
    jmp .parseloop

.trys:
    cmp edx, 's'
    jne .parseloop
    mov [srvrootstr], dword valbuf
    jmp .parseloop

.ioerror:
    mov eax, 4
    mov ebx, 1
    mov ecx, err_fileio
    mov edx, err_fileio_len
    int 0x80

.done:
    ret