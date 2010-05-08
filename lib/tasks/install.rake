
desc "Install clsi-rails - Creates the database and configures the LaTeX environment"
task :install => ['db:migrate', 'clsi:compile_chrootedlatex'] do
end

namespace :clsi do
  task :setupchroot => :environment do
    commands = [:pdflatex, :latex, :bibtex, :dvips, :dvipdf]
    for command in commands
      print "Compiling the chrooted #{command} binary...\n"
      compile_command = "gcc chrootedbinary.c -o chrooted#{command} " +
                        "-DCHROOT_DIR='\"#{LATEX_CHROOT_DIR}\"' " + 
                        "-DCOMMAND='\"/bin/#{command == :dvipdf ? :dvipdfmx : command}\"'"
      system(compile_command)
    end
    
    print "Please run the following commands as root\n" + 
          "to give the binaries permission to chroot:\n\n"
    for command in commands
      print "\tchown root:root chrooted#{command}\n"
      print "\tchmod a+s chrooted#{command}\n"
    end
  end
end
