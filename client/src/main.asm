bits 64
default rel

%include "winsock.inc"

extern ExitProcess
extern gethostbyname
extern GetStdHandle
extern GetProcessHeap
extern ReadFile
extern HeapAlloc
extern HeapReAlloc

global main

section .bss
    temp_message_storage resb 1024 ; 1kb

section .data
    hostName db "127.0.0.1", 0

    serverAddr:
        dw AF_INET
        dw 0x2823 ; Port 9000, network byte order
        dd 0 ; INADDR_ANY (0.0.0.0)
        dq 0 ; Padding

section .bss
    sock_handle resq 1

section .text
main:
    ; +40 = std input handle
    ; +48 = process heap
    ; +56 = message buffer pointer
    ; +64 = message buffer length
    ; +72 = message length
    ; +80 = lpNumberOfBytesRead for ReadFile call
    ; +88 = chunk index
    ; +96 = char storage
    sub rsp, 104

.init_socket:
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

.init_heap:
    mov ecx, -10
    call GetStdHandle
    mov [rsp + 40], rax

    call GetProcessHeap
    mov [rsp + 48], rax

    mov rcx, rax
    xor edx, edx
    mov r8d, 1024
    call HeapAlloc

    test rax, rax
    jz .exit

    mov [rsp + 56], rax

.accept_input:
    mov qword [rsp + 64], 1024
    mov [rsp + 72], 0

.read_chunk:
    mov rcx, [rsp + 40]
    lea rdx, [temp_message_storage]
    mov r8d, 1024
    lea r9, [rsp + 80]
    mov qword [rsp + 32], 0 ; overlapped = null
    call ReadFile

    test eax, eax
    jz .cleanup

    cmp dword [rsp + 80], 0
    je .cleanup

    mov qword [rsp+88], 0

.process:
    mov rax, [rsp + 88]
    cmp eax, [rsp + 80]
    jae .read_chunk

    lea r10, [temp_message_storage]
    movzx edx, byte [r10 + rax]

    inc qword [rsp + 88]

    ; newline, so message is complete
    cmp dl, 10
    je .message_complete

    ; if carriage return, just loop
    cmp dl, 13
    je .process

    mov [rsp + 96], dl

    ; if message is now longer than the buffer
    mov rax, [rsp + 72]
    add rax, 8
    cmp rax, [rsp + 64]
    jb .append

    shl qword [rsp + 64], 1

    mov rcx, [rsp + 48]
    xor edx, edx
    mov r8, [rsp + 56]
    mov r9, [rsp + 64]
    call HeapReAlloc

    test rax, rax
    jz .cleanup

    mov [rsp + 56], rax

.append:
    mov rax, [rsp + 72]
    mov rdx, [rsp + 56]
    mov cl, [rsp +96]
    mov [rdx + rax + 8], cl

    inc qword [rsp + 72]
    jmp .process

.message_complete:
    ; prepend length to the payload
    mov rax, [rsp + 72]
    bswap rax ; big endian for network byte order
    mov rdx, [rsp + 56]
    mov [rdx], rax

    ; send message
    mov rcx, [sock_handle]
    mov rdx, [rsp + 56]
    mov r8d, [rsp + 72]
    add r8d, 8
    xor r9d, r9d
    call net_send

    jmp .accept_input

.close:
    mov rcx, [sock_handle]
    call net_close

.cleanup:
    call net_cleanup

.exit:
    xor ecx, ecx
    call ExitProcess
