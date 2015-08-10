#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <errno.h>


int main(const int argc, const char *argv[]) {

  const char characters[] = "!#$%&()*+-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{}~";
  const int maxchar = strlen(characters);

  int pwdlen = 0;
  if (argc > 1) {
    sscanf(argv[1], "%d", &pwdlen);
    if (errno) {
      perror("Can't read argument: ");
      exit(1);
    }
    if (pwdlen < 2) {
      printf("Invalid password length: %s\n", argv[1]);
      exit(2);
    }
  }

  pwdlen = pwdlen ? pwdlen : 12;  /* default */
  
  srand48(time(NULL));
  for (int i = 0; i < pwdlen; i++) {
    printf("%c", characters[lrand48() % maxchar]);
  }
  printf("\n");
}
