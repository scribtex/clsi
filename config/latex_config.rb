RUN_LATEX_CHROOTED = false

if RUN_LATEX_CHROOTED
  
  # The following configuration assumes you are running latex under a chroot
  #
  # LATEX_CHOOT_DIR is a directory with a fll filesystem structure containing
  # the LaTeX binaries which will be run under a chroot.
  LATEX_CHROOT_DIR = File.join(RAILS_ROOT, 'latexchroot')

  # LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT is the directory within LATEX_CHROOT_DIR
  # in which the compiles are performed
  LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT = 'compiles'

  # LATEX_COMPILER_DIR should be the same directory as LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT
  # but relative to the root filesystem
  LATEX_COMPILE_DIR = File.join(LATEX_CHROOT_DIR, LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT)

  # These are the commands to run various binaries in the chroot. These
  # can be compiled from chrootedbinary.c. See that source file for 
  # details (don't worry, it's only short!).
  LATEX_COMMAND  = File.join(RAILS_ROOT, 'chrootedlatex')
  BIBTEX_COMMAND = File.join(RAILS_ROOT, 'chrootedbibtex')
  DVIPDF_COMMAND = File.join(RAILS_ROOT, 'chrooteddvipdf')
  DVIPS_COMMAND  = File.join(RAILS_ROOT, 'chrooteddvips')

else

  # Alternatively if you are feeling brave, or perhaps stupid, you can
  # run LaTeX from your root filesystem without a chroot. The following configuration
  # will acheive this but proceed at your own risk
  LATEX_CHROOT_DIR = File.join(RAILS_ROOT, 'latexchroot')
  LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT = File.join(RAILS_ROOT, 'latexchroot/compiles')
  LATEX_COMPILE_DIR = LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT
  PDFLATEX_COMMAND = '/usr/texbin/pdflatex'
  LATEX_COMMAND = '/usr/texbin/latex'
  BIBTEX_COMMAND = '/usr/texbin/bibtex'
  DVIPDF_COMMAND = '/usr/texbin/dvipdfmx'
  DVIPS_COMMAND = '/usr/texbin/dvips'
  
end

# These determine how long each command is allowed to run before 
# being forcefully terminated. These should be sensible defaults.
# COMPILE_TIMEOUT is the maximum time in seconds that each pass 
# of latex, pdflatex, etc. will take.
# The others determine each command individually.
COMPILE_TIMEOUT = 10 
BIBTEX_TIMEOUT = 10
DVIPDF_TIMEOUT = 10
DVIPS_TIMEOUT = 10

