#include <stdio.h>

int main(int argc, char* argv[])
{
    int ret = 0;

    printf("cmddemo2 running\n");

    if(NULL != argv[1]) {
        sscanf(argv[1], "%d", &ret);
    }

    printf("cmddemo2 return %d\n", ret);

    return ret;
}
