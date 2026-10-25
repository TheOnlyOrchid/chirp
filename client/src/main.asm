bits 64
default rel

%include "winsock.inc"

extern ExitProcess
extern gethostbyname

global main

section .data
    hostName db "127.0.0.1", 0
    message db "Chirp chirp?", 10
    messageLen equ $ - message

    serverAddr:
        dw AF_INET
        dw 0x2823 ; Port 9000, network byte order
        dd 0 ; INADDR_ANY (0.0.0.0)
        dq 0 ; Padding

section .bss
    sock_handle resq 1

section .text
main:
    sub rsp, 40

    ; init
    call net_init
    test eax, eax
    jnz .exit

    ; get socket
    call net_socket
    cmp rax, INVALID_SOCKET
    je .cleanup

    mov [sock_handle], rax

    ; resolve hostname
    lea rcx, [hostName]
    call gethostbyname

    test rax, rax
    jz .close

    mov rax, [rax + 24]
    mov rax, [rax]
    mov eax, [rax]
    mov [serverAddr + 4], eax

    ; connect
    mov rcx, [sock_handle]
    lea rdx, [serverAddr]
    mov r8d, 16
    call net_connect

    test eax, eax
    jnz .close

    ; send
    mov rcx, [sock_handle]
    lea rdx, [message]
    mov r8d, messageLen
    xor r9d, r9d
    call net_send

.close:
    mov rcx, [sock_handle]
    call net_close

.cleanup:
    call net_cleanup

.exit:
    xor ecx, ecx
    call ExitProcess
