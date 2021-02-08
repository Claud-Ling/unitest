#include <stdio.h>

extern int cmddemo1_sub(char *nstr);

int main(int argc, char* argv[])
{
    int ret;

    printf("cmddemo1 running\n");

    ret = cmddemo1_sub(argv[1] );

    printf("cmddemo1 return %d\n", ret);

    return ret;
}
