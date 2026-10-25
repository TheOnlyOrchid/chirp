bits 64
default rel

%include "winsock.inc"

extern GetStdHandle
extern WriteFile
extern ExitProcess

global main

section .data
    serverAddr:
        dw AF_INET
        dw 0x2823 ; Port 9000, network byte order
        dd 0 ; INADDR_ANY (0.0.0.0)
        dq 0 ; Padding

section .bss
    serverSock resq 1
    clientSock resq 1

    buffer resb 4096
    bytesWritten resd 1

section .text
main:
    ; 32-byte shadow space, alignment,
    ; room for fifth arg
    sub rsp, 56

    ; init
    call net_init
    test eax, eax
    jnz .exit

    ; create socket
    call net_socket
    cmp rax, INVALID_SOCKET
    je .cleanup

    ; bind port
    mov [serverSock], rax

    mov rcx, [serverSock]
    lea rdx, [serverAddr]
    mov r8d, 16
    call net_bind

    test eax, eax
    jnz .close_server

    ; listen
    mov rcx, [serverSock]
    mov edx, 5
    call net_listen

    test eax, eax
    jnz .close_server

    ; accept client
    mov rcx, [serverSock]
    xor edx, edx
    xor r8d, r8d
    call net_accept

    cmp rax, INVALID_SOCKET
    je .close_server

    mov [clientSock], rax

    ; recieve data
    mov rcx, [clientSock]
    lea rdx, [buffer]
    mov r8d, 4096
    xor r9d, r9d
    call net_recv

    ; EAX = bytes recieved
    test eax, eax
    jle .close_client

    mov dword [rsp + 48], eax

    ; get stdout
    mov ecx, -11 ; STD_OUTPUT_HANDLE
    call GetStdHandle

    ; print it all out!
    mov rcx, rax
    lea rdx, [buffer]
    mov r8d, [rsp + 48]
    lea r9, [bytesWritten]
    mov qword [rsp + 32], 0
    call WriteFile

.close_client:
    mov rcx, [clientSock]
    call net_close

.close_server:
    mov rcx, [serverSock]
    call net_close

.cleanup:
    call net_cleanup

.exit:
    xor ecx, ecx
    call ExitProcess
