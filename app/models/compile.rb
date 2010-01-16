require 'rexml/document'

class Compile
  attr_accessor :token, :user,
                :root_resource_path, :resources, 
                :compiler, :output_format
  attr_reader   :output_files, :log_files, :unique_id

  POSSIBLE_COMPILER_OUTPUT_FORMATS = {
    :pdflatex => ['pdf'],
    :latex    => ['dvi', 'pdf', 'ps']
  }

  def compiler 
    @compiler ||= 'pdflatex'
  end

  def output_format
    @output_format ||= 'pdf'
  end

  def initialize(attributes = {})
    for attribute_name, value in attributes
      self.send("#{attribute_name}=", value)
    end
    @output_files = []
    @log_files = []
  end

  def compile
    validate_compile
    write_resources_to_disk
    do_compile
    convert_to_output_format
    move_compiled_files_to_public_dir
  ensure
    move_log_files_to_public_dir
    remove_compile_directory
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

private

  def write_resources_to_disk
    for resource in self.resources.to_a
      resource.write_to_disk
    end
  end

  def do_compile
    bibtex_command = "#{tex_env_variables} #{BIBTEX_COMMAND} " +
                     "#{self.root_resource_path} &> /dev/null"

    run_with_timeout(compile_command, COMPILE_TIMEOUT)
    run_with_timeout(compile_command, COMPILE_TIMEOUT)
    run_with_timeout(bibtex_command, BIBTEX_TIMEOUT)
    run_with_timeout(compile_command, COMPILE_TIMEOUT)
  end
  
  def convert_to_output_format
    case self.compiler
    when 'pdflatex'
      input_format = 'pdf'
    when 'latex'
      input_format = 'dvi'
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
    
    for output_file in find_output_files_of_type(self.output_format)
      output_path = File.join(compile_directory, output_file)
      rel_dest_path = File.join('output', self.unique_id, output_file)
      dest_path = File.join(SERVER_PUBLIC_DIR, rel_dest_path)
      FileUtils.mv(output_path, dest_path)
      @output_files << OutputFile.new(:path => rel_dest_path)
    end
  end
  
  def move_log_files_to_public_dir
    FileUtils.mkdir_p(File.join(SERVER_PUBLIC_DIR, 'output', self.unique_id))
    
    output_log_path = File.join(compile_directory, 'output.log')
    rel_dest_log_path = File.join('output', self.unique_id, 'output.log')
    if File.exist?(output_log_path)
      FileUtils.mv(output_log_path, File.join(SERVER_PUBLIC_DIR, rel_dest_log_path))
      @log_files << OutputFile.new(:path => rel_dest_log_path)
    end
  end
  
  def remove_compile_directory
    FileUtils.rm_rf(self.compile_directory)
  end
  
  def tex_env_variables
    @tex_env_variables ||= "TEXMFOUTPUT=\"#{compile_directory}\" " +
                           "TEXINPUTS=\"$TEXINPUTS:#{compile_directory}\" " + 
                           "BIBINPUTS=\"#{compile_directory}:$BIBINPUTS\" " + 
                           "BSTINPUTS=\"#{compile_directory}:$BSTINPUTS\" "
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
    else
      raise NotImplemented # Previous checking means we should never get here!
    end
    return "#{tex_env_variables} #{command} -interaction=batchmode " + 
           "-output-directory=\"#{compile_directory_rel_to_chroot}\" -no-shell-escape " + 
           "-jobname=output #{self.root_resource_path} &> /dev/null"
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
    dvipdf_command = "#{DVIPDF_COMMAND} -o \"#{output}\" \"#{input}\" &> /dev/null"
    run_with_timeout(dvipdf_command, DVIPDF_TIMEOUT)
  end
  
  def convert_dvi_to_ps
    input = File.join(compile_directory_rel_to_chroot, 'output.dvi')
    output = File.join(compile_directory_rel_to_chroot, 'output.ps')
    dvips_command = "#{DVIPS_COMMAND} -o \"#{output}\" \"#{input}\" &> /dev/null"
    run_with_timeout(dvips_command, DVIPS_TIMEOUT)
  end
  
  # Everything below here is copied from the mathwiki code. It was ugly when
  # I first wrote it and, unlike a good wine, it hasn't improved with time. 
  # Fixing it would be good.
  def run_with_timeout(command, timeout = 10)
    start_time = Time.now
    pid = fork {
      exec(*command)
    }
    while Time.now - start_time < timeout
      if Process.waitpid(pid, Process::WNOHANG)
        return pid
      end
      sleep 0.2 # No need to check too often
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
