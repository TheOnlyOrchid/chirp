
bits 64
default rel

extern WSAStartup
extern WSACleanup
extern socket
extern closesocket
extern connect
extern bind
extern listen
extern accept
extern send
extern recv

global net_init
global net_socket
global net_close
global net_cleanup
global net_connect
global net_bind
global net_listen
global net_accept
global net_send
global net_recv

section .bss
    wsaData resb 408

section .text

; int net_init()
net_init:
    sub rsp, 40

    mov ecx, 0x0202
    lea rdx, [wsaData]
    call WSAStartup

    add rsp, 40
    ret

; SOCKET net_socket()
net_socket:
    sub rsp, 40

    mov ecx, 2
    mov edx, 1
    mov r8d, 6
    call socket

    add rsp, 40
    ret

; int net_connect(SOCKET, sockaddr*, int)
; RCX = socket
; RDX = address
; R8D = address length
net_connect:
    sub rsp, 40
    call connect
    add rsp, 40
    ret

; int net_bind(SOCKET, sockaddr*, int)
net_bind:
    sub rsp, 40
    call bind
    add rsp, 40
    ret

; int net_listen(SOCKET, int backlog)
net_listen:
    sub rsp, 40
    call listen
    add rsp, 40
    ret

; SOCKET net_accept(SOCKET, sockaddr*, int*)
net_accept:
    sub rsp, 40
    call accept
    add rsp, 40
    ret

; int net_send(SOCKET, char*, int, int)
net_send:
    sub rsp, 40
    call send
    add rsp, 40
    ret

; int net_recv(SOCKET, char*, int, int)
net_recv:
    sub rsp, 40
    call recv
    add rsp, 40
    ret

; int net_close(SOCKET)
net_close:
    sub rsp, 40
    call closesocket
    add rsp, 40
    ret

; int net_cleanup()
net_cleanup:
    sub rsp, 40
    call WSACleanup
    add rsp, 40
    ret
