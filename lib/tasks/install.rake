
desc "Install clsi-rails - Creates the database and configures the LaTeX environment"
task :install => ['db:migrate', 'clsi:compile_chrootedlatex'] do
end

namespace :clsi do
  task :compile_chrootedlatex do
    print "Compiling the chrootedlatex binary...\n\n"
    system("gcc chrootedlatex.c -o chrootedlatex -DCHROOT_DIR='\"#{LATEX_CHROOT_DIR}\"' -DLATEX_CMD='\"/bin/pdflatex\"'")
    print "\nDone!\n\n"
    print "Compiling the chrootedbibtex binary...\n\n"
    system("gcc chrootedlatex.c -o chrootedbibtex -DCHROOT_DIR='\"#{LATEX_CHROOT_DIR}\"' -DLATEX_CMD='\"/bin/bibtex\"'")
    print "\nDone!\n\n"
    print "Please run the following commands as root to allow the binary to chroot:\n\n"
    print "\tchown root:root chrootedlatex\n"
    print "\tchmod a+s chrootedlatex\n"
    print "\tchown root:root chrootedbibtex\n"
    print "\tchmod a+s chrootedbibtex\n\n"
  end
end
