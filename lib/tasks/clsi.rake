namespace :clsi do
  desc "Create the database and configure the LaTeX environment"
  task :setup => ['db:migrate', 'clsi:compile'] do
  end
  
  desc "Compile the chrooted LaTeX binaries"
  task :compile => :environment do
    commands = [:pdflatex, :latex, :bibtex, :dvips, :dvipdf, :makeindex]
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
  
  desc "Remove cached urls that haven't been access recently"
  task :clean_cache => :environment do
    UrlCache.destroy_all(['last_accessed < ?', (ENV['CACHE_AGE'] || 5).to_i.days.ago])
  end
  
  desc "Removes old compiles from the output directory" 
  task :clean_output => :environment do
    system("find #{SERVER_PUBLIC_DIR}/output -mindepth 1 -maxdepth 1 -mmin +60 | xargs rm -rf")
  end
end
