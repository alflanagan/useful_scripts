#include <unistd.h>
#include <libgen.h>
#include <string.h>
#include <fcntl.h>
#include <stdio.h>
#include <errno.h>

int fcopy(int fileno) {
  unsigned char buff[1024] = {0};
  unsigned char zbuff = (unsigned char)0;
  ssize_t count = 0;
  while ((count = read(fileno, buff, sizeof(buff))) > 0) {
    ssize_t pos = 0;
    while (pos < count) {
      if (buff[pos] == (unsigned char)'\n') {
        write(fileno, "\0", 1);
      }
      write(1, buff + pos, 1);
      pos++;
    }
    fsync(fileno);
  }
  // count == 0 OR error occurred
  if (count < 0) {
    write(2, "READ ERROR!", 11);
  }
}

int main(const int argc, char *argv[]) {

  int	fd, i, r;

  if (argc == 1)
    return (fcopy(0));

  for (i = 1, r = 1; i < argc; i++) {
    if (argv[i][0] == '-' && argv[i][1] == '\0')
      fd = 0;
    else {
      fd = open(argv[i], O_RDONLY, 0666);
      if (fd < 0) {
        char *s = strerror(errno);
        char *base = basename(argv[0]);
        write(2, base, strlen(base));
        write(2, ": cannot open ", 17);
        write(2, argv[i], strlen(argv[i]));
        write(2, ": ", 2);
        write(2, s, strlen(s));
        write(2, "\n", 1);
        continue;
      }
    }
    r = fcopy(fd);
    if (fd != 0)
      close(fd);
  }
  return (r);
}
