#include <stdio.h>
#include <sys/types.h>
extern int64_t test_16();
extern int64_t global_var;
int main()
{
  
  int64_t i, j, k;
  int errors=0;
  int success=0;

  
  // printf("global_var: %d, test_16(): %d\n",global_var,test_16());
  if (global_var!=test_16())
      errors++;
  else
      success++;
  // printf("global_var: %d",global_var);
  printf("success,%d\nerrors,%d\ntotal,%d\n",success,errors,success+errors);

  return 0;
}