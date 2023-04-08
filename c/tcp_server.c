#include "./signal.h"

#include "./tcp_server.h"
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

static struct sockaddr_in sa;
static int socket_fd;

void server_init(int port) {
  socket_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  if (socket_fd == -1) {
    perror("cannot create socket");
    exit(EXIT_FAILURE);
  }
  int flags = fcntl(socket_fd, F_GETFL);

  if (socket_fd == -1) {
    perror("cannot get flags on socket");
    exit(EXIT_FAILURE);
  }
  fcntl(socket_fd, F_SETFL, flags | O_NONBLOCK | 15 | SO_KEEPALIVE);

  if (socket_fd == -1) {
    puts("cannot set O_NONBLOCK | SO_REUSEPORT | SO_KEEPALIVE");
    exit(EXIT_FAILURE);
  }

  int tcp_fastopen = 1;
  int tcp_keepidle = 5;
  int tcp_quickack = 1;
  int tcp_nodelay = 1;
  int setopts = setsockopt(socket_fd, IPPROTO_TCP, TCP_FASTOPEN, &tcp_fastopen,
                           sizeof(tcp_fastopen));
  setopts += setsockopt(socket_fd, IPPROTO_TCP, TCP_KEEPIDLE, &tcp_keepidle,
                        sizeof(tcp_keepidle));
  setopts += setsockopt(socket_fd, IPPROTO_TCP, TCP_QUICKACK, &tcp_quickack,
                        sizeof(tcp_keepidle));
  setopts += setsockopt(socket_fd, IPPROTO_TCP, TCP_NODELAY, &tcp_nodelay,
                        sizeof(tcp_keepidle));

  // could look at removing this for cross compatability.
  if (setopts >= 1) {
    perror("Zignature is designed for newer kernels and linux only.");
    perror("Many options were not set correctly on this machine");
    exit(EXIT_FAILURE);
  }

  memset(&sa, 0, sizeof sa);

  sa.sin_family = AF_INET;
  sa.sin_port = htons(port);
  sa.sin_addr.s_addr = htonl(INADDR_ANY);

  if (bind(socket_fd, (struct sockaddr *)&sa, sizeof sa) == -1) {
    perror("bind failed");
    close(socket_fd);
    exit(EXIT_FAILURE);
  }
}

void server_listen(int max_conns) {
  if (listen(socket_fd, max_conns *= 2) == -1) {
    perror("listen failed");
    close(socket_fd);
    exit(EXIT_FAILURE);
  }
}

int server_client_read_new() {
  int cd = accept(socket_fd, NULL, NULL);
  if (cd == -1) {
    return -errno;
  }
  return cd;
}

int server_client_read(int cd, char *buffer, size_t left) {
  int rd = read(cd, buffer, left);
  if (rd >= 0) {
    return rd;
  }
  return -errno;
}

int server_client_write(int cd, const char *buffer, size_t buffer_size) {
  int wd = write(cd, buffer, buffer_size);
  if (wd >= 0) {
    return wd;
  }
  return -errno;
}

int server_close(int client_id) { return -close(client_id); }
