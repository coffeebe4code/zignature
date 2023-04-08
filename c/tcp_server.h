#pragma once
#include "stdbool.h"
#include "stdlib.h"

int server_client_read(int cd, char *buffer, size_t left);
int server_client_write(int cd, const char *buffer, size_t buffer_size);
int server_close(int fd);
int server_client_read_new();
void server_init(int port);
void server_listen(int max_conns);
