#include <stdio.h>
#include <sys/types.h>
extern int64_t test_15(int64_t x);

int64_t test_function(int64_t x){
    int64_t ret;
    switch(x){
        case -3:ret = -3;
                break;
        case -2:ret = -2;
                break;
        case -1:ret = 3;
                break;
        case 1:ret = 1;
                break;
        default: return 0;
    }
    return ret;
}

int main()
{
  
  int64_t i, j, k;
  int errors=0;
  int success=0;

  for (i=-19; i<100; i++)
  {
  int64_t test_op = test_15(i);
  int64_t sample_op = test_function(i);
  //printf("test_op: %d, sample_op: %d\n",test_op,sample_op);
    if (test_op!=sample_op)
	  errors++;
	else
	  success++;
  }
  printf("success,%d\nerrors,%d\ntotal,%d\n",success,errors,success+errors);

  return 0;
}