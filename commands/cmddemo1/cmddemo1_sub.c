#include <stdio.h>

int cmddemo1_sub(char *nstr)
{
    int nret = 0;

    printf("run in cmddemo1_sub(%s)\n", nstr);

    if(NULL != nstr) {
        sscanf(nstr, "%d", &nret);
    }

    printf("cmddemo1_sub() return %d\n", nret);
    return nret;
}
