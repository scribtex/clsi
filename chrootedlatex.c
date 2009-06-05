#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>

/* You should set CHROOT_DIR and LATEX_CMD when you compile this *
 *     gcc chrootedlatex.c -o chrootedlatex \\                   *
 *     -DCHROOT_DIR='"/chroot/dir"' -DLATEX_CMD='"/bin/latex"'   */

int main(int argc, char *argv[], char *envp[]) {

  /* Try to chroot and then change directory into the the new root. */
  if (chroot(CHROOT_DIR) || chdir("/")) {
    fprintf (stderr, "Failed to chroot into %s: %s\n", CHROOT_DIR, strerror(errno));
    return EXIT_FAILURE;
  }

  /* Execute LaTeX within the chroot and pass it all the arguments we recieved */
  argv[0] = LATEX_CMD;
  execve(LATEX_CMD, argv, envp);

  /* If we are here then execve return and thus failed. */
  perror("Could not run latex inside the chroot");
}
