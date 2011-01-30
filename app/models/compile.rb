class Compile
  attr_accessor :token, :user,
                :root_resource_path, :resources, 
                :compiler, :output_format
  attr_reader   :output_files, :log_files, :unique_id,
                :status, :error_type, :error_message,
                :bibtex_ran, :makeindex_ran

  POSSIBLE_COMPILER_OUTPUT_FORMATS = {
    :pdflatex => ['pdf'],
    :latex    => ['dvi', 'pdf', 'ps'],
    :xelatex  => ['pdf']
  }

  def compiler
    @compiler ||= 'pdflatex'
  end

  def output_format
    @output_format ||= 'pdf'
  end

  def initialize(attributes = {})
    self.root_resource_path = attributes[:root_resource_path]
    self.token = attributes[:token]
    
    self.compiler = attributes[:compiler]
    self.output_format = attributes[:output_format]

    self.resources = []
    for resource in attributes[:resources].to_a
      self.resources << Resource.new(
        resource[:path],
        resource[:modified_date],
        resource[:content],
        resource[:url],
        self
      )
    end
    
    @output_files = []
    @log_files = []
    @status = :unprocessed
    @bibtex_ran = false
    @makeindex_ran = false
  end

  def compile
    @start_time = Time.now
    validate_compile
    write_resources_to_disk
    do_compile
    convert_to_output_format
    move_compiled_files_to_public_dir
    @status = :success
  rescue CLSI::CompileError => e
    @status = :failure
    @error_type = e.class.name.demodulize
    @error_message = e.message
  ensure
    move_log_files_to_public_dir
    write_response_to_public_dir
    remove_compile_directory unless PRESERVE_COMPILE_DIRECTORIES
    record_in_compile_log
  end

  def validate_compile
    if self.user.blank?
      self.user = User.find_by_token(self.token)
      raise CLSI::InvalidToken, 'user does not exist' if self.user.nil?
    end
    
    unless POSSIBLE_COMPILER_OUTPUT_FORMATS.has_key?(self.compiler.to_sym)
      raise CLSI::UnknownCompiler, "#{self.compiler} is not a valid compiler"
    end
    
    unless POSSIBLE_COMPILER_OUTPUT_FORMATS[self.compiler.to_sym].include?(self.output_format)
      raise CLSI::ImpossibleOutputFormat, "#{self.compiler} cannot produce #{self.output_format} output"
    end
  end
  
  def unique_id
    @unique_id ||= generate_unique_string
  end
  
  def compile_directory
    @compile_directory ||= File.join(LATEX_COMPILE_DIR, self.unique_id)
  end
  
  def to_xml
    xml = Builder::XmlMarkup.new
    xml.instruct!

    xml.compile do
      xml.compile_id(self.unique_id)
      
      if self.status == :failure
        xml.status('failure')
        xml.error do
          xml.type self.error_type
          xml.message self.error_message
        end
      else
        xml.status(self.status.to_s)
      end
   
      unless self.output_files.empty?
        xml.output do
          for file in self.output_files
            xml.file(:url => file.url, :type => file.type, :mimetype => file.mimetype)
          end
        end
      end
  
      unless self.log_files.empty?
        xml.logs do
          for file in self.log_files
            xml.file(:url => file.url, :type => file.type, :mimetype => file.mimetype)
          end
        end
      end
    end
  end

private

  def write_resources_to_disk
    File.umask(0002)
    
    for resource in self.resources.to_a
      resource.write_to_disk
    end
  end

  def do_compile
    run_compiler
    
    aux_file_content = read_aux_files
    if aux_file_content.include? '\\citation' or aux_file_content.include? '\\bibdata' or aux_file_content.include? '\\bibstyle'
      modify_aux_files
      run_bibtex
      run_latex_again = true
      @bibtex_ran = true
    end
    
    if File.exist?(File.join(compile_directory, 'output.idx'))
      run_makeindex
      run_latex_again = true
      @makeindex_ran = true
    end
    
    if log_complains_about_references? or run_latex_again
      run_compiler
    end
    
    if log_complains_about_references?
      run_compiler
    end
  end

  def log_complains_about_references?
    log_content = read_log
    log_content.include?('There were undefined references') ||
    log_content.include?('There were undefined citations') ||
    log_content.include?('LaTeX Warning: Label(s) may have changed. Rerun to get cross-references right.') ||
    log_content.include?('LaTeX Warning: Citation') ||
    log_content.include?('No file output.toc')
  end
  
  def run_bibtex
    bibtex_command = ['env', tex_env_variables, BIBTEX_COMMAND, "#{compile_directory_rel_to_chroot}/output"].flatten
    run_with_timeout(bibtex_command, BIBTEX_TIMEOUT)
  end
  
  def run_makeindex
    makeindex_command = [
      MAKEINDEX_COMMAND,
      '-o', "#{compile_directory_rel_to_chroot}/output.ind",
      "#{compile_directory_rel_to_chroot}/output.idx"
    ]
    run_with_timeout(makeindex_command, COMPILE_TIMEOUT)
  end
  
  def run_compiler
    run_with_timeout(compile_command, COMPILE_TIMEOUT)
  end
  
  def read_aux_files
    aux_file_paths = Dir.entries(self.compile_directory).reject{|e| not e.match(/\.aux$/)}
    aux_file_paths.collect!{|p| File.join(self.compile_directory, p)}
    return aux_file_paths.collect{|p| File.read(p)}.join("\n")
  end
  
  def modify_aux_files
    aux_file_names = Dir.entries(self.compile_directory).reject{|e| not e.match(/\.aux$/)}
    aux_file_paths = aux_file_names.collect{|n| File.join(self.compile_directory, n)}
    for aux_file in aux_file_paths
      content = File.read(aux_file)
      content.gsub!(/^\\@input\{(.*)\}$/, "\\@input{#{compile_directory_rel_to_chroot}/\\1}")
      File.open(aux_file, 'w') {|f|
        f.write(content)
      }
    end
  end
  
  def read_log
    log_file_path = File.join(self.compile_directory, 'output.log')
    return '' unless File.exist?(log_file_path)
    File.read(log_file_path)
  end
  
  def convert_to_output_format
    case self.compiler
    when 'pdflatex'
      input_format = 'pdf'
    when 'latex'
      input_format = 'dvi'
    when 'xelatex'
      input_format = 'pdf'
    end
    ensure_output_files_exist(input_format)
    conversion_method = "convert_#{input_format}_to_#{self.output_format}"
    if self.respond_to?(conversion_method, true)
      self.send(conversion_method)
    else
      raise CLSI::ImpossibleFormatConversion, "can't convert #{input_format} to #{self.output_format}"
    end
  end

  def move_compiled_files_to_public_dir
    FileUtils.mkdir_p(File.join(SERVER_PUBLIC_DIR, 'output', self.unique_id))
    
    for existing_file in find_output_files_of_type(self.output_format)
      existing_path = File.join(compile_directory, existing_file)
      relative_output_path = File.join(relative_output_dir, existing_file)
      output_path = File.join(SERVER_PUBLIC_DIR, relative_output_path)
      FileUtils.mv(existing_path, output_path)
      @output_files << OutputFile.new(:path => relative_output_path)
    end
  end
  
  def move_log_files_to_public_dir
    FileUtils.mkdir_p(output_dir)
    
    existing_log_path = File.join(compile_directory, 'output.log')
    relative_output_log_path = File.join(relative_output_dir, 'output.log')
    if File.exist?(existing_log_path)
      FileUtils.mv(existing_log_path, File.join(SERVER_PUBLIC_DIR, relative_output_log_path))
      @log_files << OutputFile.new(:path => relative_output_log_path)
    end
  end
  
  def remove_compile_directory
    FileUtils.rm_rf(self.compile_directory)
  end
  
  def write_response_to_public_dir
    FileUtils.mkdir_p(output_dir)
    File.open(File.join(output_dir, 'response.xml'), 'w') do |f|
      f.write(self.to_xml)
    end
  end
  
  def record_in_compile_log
    CompileLog.create(
      :user => user,
      :time_taken => ((Time.now.to_f - @start_time.to_f) * 1000).to_i, # Time in milliseconds
      :bibtex_ran => @bibtex_ran,
      :makeindex_ran => @makeindex_ran
    )
  end
  
  def tex_env_variables
    @tex_env_variables ||= ["TEXMFOUTPUT=#{compile_directory_rel_to_chroot}",
                            "TEXINPUTS=#{compile_directory_rel_to_chroot}:",
                            "BIBINPUTS=#{compile_directory_rel_to_chroot}",
                            "BSTINPUTS=#{compile_directory_rel_to_chroot}:"]
  end
  
  def output_dir
    File.join(SERVER_PUBLIC_DIR, relative_output_dir)
  end
  
  def relative_output_dir
    File.join('output', self.unique_id)
  end
  
  def compile_directory_rel_to_chroot
    @compile_directory_rel_to_chroot ||= File.join(LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT, self.unique_id)
  end
  
  def compile_command
    case self.compiler
    when 'pdflatex'
      command = PDFLATEX_COMMAND
    when 'latex'
      command = LATEX_COMMAND
    when 'xelatex'
      command = XELATEX_COMMAND
    else
      raise NotImplemented # Previous checking means we should never get here!
    end
    return ["env"] + tex_env_variables + [command, "-interaction=batchmode",
            "-output-directory=#{compile_directory_rel_to_chroot}", "-no-shell-escape", 
            "-jobname=output", self.root_resource_path]
  end
  
  # Returns a list of output files of the given type. Will raise a CLSI::NoOutputFile if no output
  # files of the given type exist.
  def find_output_files_of_type(type)
    file_name = "output.#{type}"
    output_path = File.join(compile_directory, file_name)
    raise CLSI::NoOutputProduced, 'no compiled documents were produced' unless File.exist?(output_path)
    return [file_name]
  end
  
  def ensure_output_files_exist(type)
    find_output_files_of_type(type)
  end
    
  def convert_pdf_to_pdf
    # Nothing to do!
  end
  
  def convert_dvi_to_dvi
    # Nothing to do!    
  end
  
  def convert_dvi_to_pdf
    input = File.join(compile_directory_rel_to_chroot, 'output.dvi')
    output = File.join(compile_directory_rel_to_chroot, 'output.pdf')
    dvipdf_command = "env TEXPICTS=#{compile_directory_rel_to_chroot} #{DVIPDF_COMMAND} \"#{input}\" \"#{output}\" &> /dev/null"
    run_with_timeout(dvipdf_command, DVIPDF_TIMEOUT)

    # We need to wait a short while for the pdf to appear
    start_time = Time.now
    while Time.now - start_time < 3.seconds do
      break if File.exist?(File.join(compile_directory, 'output.pdf'))
      sleep 0.1 if (Time.now - start_time > 0.3) # No need to check to often if it's taking a while
    end
    Rails.logger.info("I was waiting #{Time.now - start_time} seconds for the dvi to be converted")
  end
  
  def convert_dvi_to_ps
    input = File.join(compile_directory_rel_to_chroot, 'output.dvi')
    output = File.join(compile_directory_rel_to_chroot, 'output.ps')
    dvips_command = "env TEXPICTS=#{compile_directory_rel_to_chroot} #{DVIPS_COMMAND} -o \"#{output}\" \"#{input}\" &> /dev/null"
    run_with_timeout(dvips_command, DVIPS_TIMEOUT)
    
    # We need to wait a short while for the ps to appear
    start_time = Time.now
    while Time.now - start_time < 3.seconds do
      break if File.exist?(File.join(compile_directory, 'output.ps'))
      sleep 0.1 if (Time.now - start_time > 0.3) # No need to check to often if it's taking a while
    end
    Rails.logger.info("I was waiting #{Time.now - start_time} seconds for the dvi to be converted")
  end
  
  # Everything below here is copied from the mathwiki code. It was ugly when
  # I first wrote it and it hasn't improved with time. 
  # Fixing it would be good.
  def run_with_timeout(command, timeout = 10)
    start_time = Time.now
    pid = fork {
      exec(*command)
    }
    while Time.now - start_time < timeout
      if Process.waitpid(pid, Process::WNOHANG)
        Rails.logger.info "(#{Time.now - start_time} seconds) #{command.to_a.join(' ')}"
        return pid
      end
      sleep 0.1 if (Time.now - start_time > 0.3) # No need to check too often if it's taking a while
    end
    
    # Process never finished
    kill_process(pid)
    raise CLSI::Timeout, "the compile took too long to run and was aborted"
  end
  
  def kill_process(pid)
    child_pids = %x[ps -e -o 'ppid pid' | awk '$1 == #{pid} { print $2 }'].split
    child_pids.collect{|cpid| kill_process(cpid.to_i)}
    Process.kill('INT', pid)
    Process.kill('HUP', pid)
    Process.kill('KILL', pid)
  end
end
