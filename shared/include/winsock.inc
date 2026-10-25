%ifndef WINSOCK_INC
%define WINSOCK_INC

%define AF_INET       2
%define SOCK_STREAM   1
%define IPPROTO_TCP   6
%define INVALID_SOCKET -1

extern net_init
extern net_socket
extern net_close
extern net_cleanup
extern net_connect
extern net_bind
extern net_listen
extern net_accept
extern net_send
extern net_recv

%endif
