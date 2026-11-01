bits 64
default rel

%include "winsock.inc"

extern GetStdHandle
extern WriteFile
extern ExitProcess
extern GetProcessHeap
extern HeapAlloc
extern HeapReAlloc

global main

section .rdata
    CRLF db 13, 10

section .data
    serverAddr:
        dw AF_INET
        dw 0x2823 ; Port 9000, network byte order
        dd 0 ; INADDR_ANY (0.0.0.0)
        dq 0 ; Padding

section .bss
    serverSock resq 1
    clientSock resq 1

    temp_buffer resb 1024
    bytesWritten resd 1

section .text
main:
    ; +64 = process heap
    ; +72 = message buffer len
    ; +80 = message buffer pointer
    ; +88 = message length
    ; +96 = bytes recieved so far
    ; +104 = rbx saved
    sub rsp, 120
    mov [rsp + 104], rbx

.init_heap:
    call GetProcessHeap
    mov [rsp + 64], rax

    mov rcx, rax
    xor edx, edx
    mov r8d, 1024
    call HeapAlloc

    test rax, rax
    jz .exit

    mov [rsp + 80], rax
    mov qword [rsp + 72], 1024

.init_socket:
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

.accept_client:
    ; accept client
    mov rcx, [serverSock]
    xor edx, edx
    xor r8d, r8d
    call net_accept

    cmp rax, INVALID_SOCKET
    je .close_server

    mov [clientSock], rax

.recieve_length:
    mov qword [rsp + 96], 0
.read_length:
    ; recieve the length
    mov rcx, [clientSock]

    lea rdx, [rsp + 88]
    add rdx, [rsp + 96]

    mov r8d, 8
    sub r8d, [rsp + 96]

    xor r9d, r9d
    call net_recv

    test eax, eax
    jle .close_client

    cmp eax, 8
    jne .close_client

    add [rsp + 96], rax

    mov rax, [rsp + 88]
    bswap rax
    mov [rsp + 88], rax

    cmp qword [rsp + 96], 8
    jb .read_length

    ; Limit incoming messages to 16 mb~
    cmp rax, 17000000
    ja .close_client

    mov qword [rsp + 96], 0

    ; if we have enough heap memory
    mov rax, [rsp + 72]
    cmp rax, [rsp + 88]
    jae .recieve_payload

    ; reserve enough memory for the message length
    mov rcx, [rsp + 64]
    xor edx, edx
    mov r8, [rsp + 80]
    mov r9, [rsp + 88]
    call HeapReAlloc

    test rax, rax
    jz .close_client

    mov [rsp + 80], rax

    mov rax, [rsp + 88]
    mov [rsp + 72], rax

.recieve_payload:
    mov rax, [rsp + 96]
    cmp rax, [rsp + 88]
    jae .message_complete

    ; recieve data
    mov rcx, [clientSock]

    mov rdx, [rsp + 80]
    add rdx, [rsp + 96]

    mov r8d, [rsp + 88]
    sub r8d, [rsp + 96]

    xor r9d, r9d
    call net_recv

    ; EAX = bytes recieved
    test eax, eax
    jle .close_client

    add [rsp + 96], rax
    jmp .recieve_payload

.message_complete:
    ; print it all out!
    mov ecx, -11
    call GetStdHandle

    mov rbx, rax

    mov rcx, rbx
    mov rdx, [rsp + 80]
    mov r8d, [rsp + 88]
    lea r9, [bytesWritten]
    mov qword [rsp + 32], 0
    call WriteFile

    ; print a newline
    mov ecx, -11
    call GetStdHandle

    mov rcx, rbx
    lea rdx, [CRLF]
    mov r8d, 2
    lea r9, [bytesWritten]
    mov qword [rsp + 32], 0
    call WriteFile

    jmp .recieve_length

.close_client:
    mov rcx, [clientSock]
    call net_close
    jmp .accept_client

.close_server:
    mov rcx, [serverSock]
    call net_close

.cleanup:
    call net_cleanup

.exit:
    xor ecx, ecx
    mov rbx, [rsp + 104]
    call ExitProcess
