#include <stdio.h>

int main(int argc, char *argv[])
{
    for (int i = 0; i < argc; i++)
    {
        fprintf(stdout, "Arg %d: %s", i, argv[1]);
    }

    return 0;
}