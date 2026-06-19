#ifndef JEKCAT_H
#define JEKCAT_H
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

int write_all_bytes(const char *buffer, ssize_t num_bytes);

int copy_fd_to_stdout(int fd);

int get_fd(const char *file_name);

#endif
