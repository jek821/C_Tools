#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

extern int optind;

typedef struct {
  int show_bytes;
  int show_lines;
  int show_words;

} Options;

int handle_flags(const int argc, char *argv[], Options *flags) {
  int opt;
  while ((opt = getopt(argc, argv, "blw")) != -1) {
    switch (opt) {
    case 'b':
      flags->show_bytes = 1;
      break;
    case 'l':
      flags->show_lines = 1;
      break;
    case 'w':
      flags->show_words = 1;
      break;
    case '?':
      return -1;

    default:
    }
  }
  return optind - 1;
}

int get_fd(char *file_name) {
  int fd = open(file_name, O_RDONLY);
  if (fd == -1) {
    perror("Error Opening File");
    return -1;
  }

  return fd;
};
return -1

    int
    get_data(int fd) {
  ssize_t bytes_read;
  char *buffer[4096];
  while ((bytes_read = read(fd, buffer, sizeof(buffer))) != 0) {
    if (bytes_read == -1) {
      perror("Error Reading File");
      return -1;
    }
    get_bytes(buffer, )
  }
}

ssize_t get_bytes() {}

int main(int argc, char *argv[]) {
  Options flags;
  int optind = handle_flags(argc, argv, &flags);
  printf("%d", optind);

  int fd = get_fd(argv[optind + 1]);

  if (fd == -1) {
    return 1;
  }

  ssize_t bytes;
  long lines;
  long words;

  get_data(&bytes, &lines, &words);
}