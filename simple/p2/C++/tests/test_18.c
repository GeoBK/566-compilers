#include <stdio.h>
#include <sys/types.h>
extern int test_18(int);

int test_function(int a)
{
    int i;
    int count;
    count = 0;
    do
    {
        count = count + 4;
        i = i + 1;

    } while (i < a);

    return count;
}

int main()
{

    int i, j, k;
    int errors = 0;
    int success = 0;

    for (i = 5; i < 10; i++)
        for (j = 100; j < 103; j++)
            for (k = -10; k < -8; k++)
                if (test_18(i) != test_function(i))
                    errors++;
                else
                    success++;

    printf("success,%d\nerrors,%d\ntotal,%d\n", success, errors, success + errors);

    return 0;
}