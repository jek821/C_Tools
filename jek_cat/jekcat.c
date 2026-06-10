#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>


char buffer[10];
ssize_t bytes_read;

int main(int argc, char* argv[]){
    if (argc > 1){
        int fd = open(argv[1], O_RDONLY);
        if (fd == -1){
            perror("open");
            return 1;
        }

        while (1){
            bytes_read = read(fd, buffer, 10);
            if (bytes_read == -1){
                perror("read");
                close(fd);
                return 1;
            }
            if (bytes_read == 0){
                close(fd);
                return 0;
            }

            if (bytes_read > 0){
                write(STDOUT_FILENO, buffer, bytes_read);
            }
        }
    }
}