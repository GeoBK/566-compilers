#include <stdio.h>
#include <sys/types.h>
extern int64_t test_17();
int fi(){
    return 5;
}
int test_function(){
    return 2*fi();
}

int main()
{
  
  int64_t i, j, k;
  int errors=0;
  int success=0;

  
  //printf("test_o/p: %d, expected_o/p: %d\n",test_17(),test_function());
  if (test_function()!=test_17())
      errors++;
  else
      success++;
  // printf("global_var: %d",global_var);
  printf("success,%d\nerrors,%d\ntotal,%d\n",success,errors,success+errors);

  return 0;
}