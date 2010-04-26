#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>

/* You should set CHROOT_DIR and COMMAND when you compile this *
 *     gcc chrootedlatex.c -o chrootedlatex \\                   *
 *     -DCHROOT_DIR='"/chroot/dir"' -DCOMMAND='"/bin/latex"'   */

int main(int argc, char *argv[], char *envp[]) {

  /* Try to chroot and then change directory into the the new root. */
  if (chroot(CHROOT_DIR) || chdir("/")) {
    fprintf (stderr, "Failed to chroot into %s: %s\n", CHROOT_DIR, strerror(errno));
    return EXIT_FAILURE;
  }

  /* Execute the command within the chroot and pass it all the arguments we recieved */
  argv[0] = COMMAND;
  execve(COMMAND, argv, envp);

  /* If we are here then execve returned and thus failed. */
  perror("Could not run latex inside the chroot");
}
