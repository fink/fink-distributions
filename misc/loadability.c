#include <stdlib.h>
#include <stdio.h>
#include <dlfcn.h>

int main(int argc, char **argv) {
  int i;
  int exitcode=0;
  if(!argv[1]) {
    printf("No files specified.\nUsage: %s [list of binary files to dlopen]\n", argv[0]);
    exit(1);
  }
  
  for(i=1; i<argc; i++) {
    char *module=dlopen(argv[i], RTLD_NOW);
    if(!module) {
      printf("dlopen(%s) failed: %s\n", argv[i], dlerror());
      exitcode=1;
    }
  }
  exit(exitcode);
}
