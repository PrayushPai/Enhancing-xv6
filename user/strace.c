#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main(int argc, char *argv[])
{
    if (argc < 3 || atoi(argv[1]) == -1)
    {
        printf("Usage: strace mask command [args]\n");
        exit(0);
    }

    if (trace(atoi(argv[1])) < 0)
    {
        printf("strace: trace failed\n");
        exit(0);
    }
    exec(argv[2], argv + 2);
    exit(0);
}