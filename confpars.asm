section .bss
    keybuf: RESB 64
    valbuf: RESB 1024

section .data
    globalpath db "/etc/pawserv/pawserv.conf", 0
    localpath db "./pawserv.conf", 0

    dot db '.', 0

    ; settings
    srvrootstr dq dot
    bashrootstr dq 0
    srv_anonymous db 0
    srv_logaccess db 1

    

    err_confnotfound db "ERROR: No pawserv.conf file found!", 10, 0
    err_confnotfound_len equ $ - err_confnotfound
    err_fileio db "ERROR: I/O failure when reading file", 10, 0
    err_fileio_len equ $ - err_fileio
    err_syntaxerr db "ERROR: Syntax error in config file", 10, 0
    err_syntaxerr_len equ $ - err_syntaxerr

section .text

global openconfig
global die

extern filebuf

openconfig:
    ; try finding in current folder first
    mov eax, 5
    mov ebx, localpath
    mov ecx, 0 ; O_RDONLY
    xor edx, edx
    int 0x80
    cmp eax, 0
    jge .getnewbuf
    
    ; try global
    mov eax, 5
    mov ebx, globalpath
    mov ecx, 0 ; O_RDONLY
    xor edx, edx
    int 0x80
    cmp eax, 0
    jge .getnewbuf

    ; fail
    mov eax, 4
    mov ebx, 1
    mov ecx, err_confnotfound
    mov edx, err_confnotfound_len
    int 0x80
    jmp .parsefail

    .getnewbuf:
        push eax ; fd

        mov edx, 4096
        mov ecx, filebuf
        mov ebx, eax
        mov eax, 3
        int 0x80
        cmp eax, 0
        jl .parsefail
        je .parsedone

    .parse:
        mov ebx, filebuf ; crt read ptr
        mov edi, keybuf ; crt write ptr
        mov ecx, 64 ; how much still allowed to write?

        xor ebp, ebp ; state (0 - value, 4 - key)

        push 0 ; key buf len (-4)
        push 0 ; value buf len

        .parsechar:
            mov edx, ebx
            sub edx, filebuf
            cmp edx, 4096
            jge .getnewbuf
            
            cmp eax, 0
            je .parse
            movzx edx, byte [ebx] ; get crt char in file

            inc ebx
            dec eax

            cmp edx, '#'
            jne .notcomment

            ;comment
            xor ecx, ecx
            jmp .parsechar

            .notcomment:
            cmp edx, '='
            jne .notequal

            ;equals
            mov ebp, 4
            mov edi, valbuf
            mov ecx, 1023
            jmp .parsechar

            .notequal:
            cmp edx, '\n'
            je .linedone

            cmp ecx, 0
            je .parsechar
            mov [edi], edx
            dec ecx
            sub esp, ebp
            mov [esp], edi ; save file pointer in appropriate place
            add esp, ebp

            jmp .parsechar

        .linedone:
            cmp ebp, 0
            je .parse

            mov eax, valbuf
            pop ebx
            call stripspace
            pop ecx
            push eax ; value beginning
            push ebx ; value len
            mov eax, keybuf
            mov ecx, ebx
            call stripspace
            ; key begin - eax, key len - ebx
            
            ; it's ok to check for just the first character for now
            ; that's faster but we will need to fix in the future
            movzx ecx, byte [eax]
            pop ebx
            pop eax

            cmp ecx, 'a'
            jg .chkb
            mov ecx, [eax]
            sub ecx, '0'
            mov [srv_anonymous], ecx

            .chkb:
            cmp ecx, 'b'
            jg .chkl
            mov [bashrootstr], eax

            .chkl:
            cmp ecx, 'l'
            jg .chks
            mov ecx, [eax]
            sub ecx, '0'
            mov [srv_logaccess], ecx

            .chks:
            cmp ecx, 's'
            jg .unknownkey
            mov [srvrootstr], eax

        .unknownkey:
            mov eax, 4
            mov ebx, 1
            mov ecx, err_syntaxerr
            mov edx, err_syntaxerr_len
            int 0x80
            jmp .parsechar

        pop eax

    .parsefail:
        mov eax, 4
        mov ebx, 1
        mov ecx, err_fileio
        mov edx, err_fileio_len
        int 0x80


    .parsedone:
        ret

stripspace:
    ; eax - string beginning
    ; ebx - string length
    ; ecx ruined
    add ebx, eax
    .leftchar:
        movzx ecx, byte [eax]
        cmp ecx, ' '
        jne .rightchar
        
        cmp eax, ebx
        jg .done
        inc eax
        jmp .leftchar
    .rightchar:
        mov ecx, [eax+ebx]
        cmp ecx, ' '
        jne .done

        cmp eax, ebx
        jg .done
        dec ebx
        jmp .rightchar
    .done:
        sub ebx, eax
        ret