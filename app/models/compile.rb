require 'rexml/document'

class Compile
  attr_accessor :user, :project, :root_resource_path, :resources, :status, :return_files, :compiler, :output_format

  def compiler 
    @compiler ||= 'pdflatex'
  end

  def output_format
    @output_format ||= 'pdf'
  end

  def initialize
    @status = :not_started
    @return_files = []
  end

  # Create a new Compile instance and load it with the information from the
  # request.
  def self.new_from_request(xml_request)
    compile = Compile.new
    compile.load_request(xml_request)
    return compile
  end

  # Extract all the information for the compile from the request
  def load_request(xml_request)
    request = parse_request(xml_request)

    @root_resource_path = request[:root_resource_path]
    
    token = request[:token]
    @user = User.find_by_token(token)
    raise CLSI::InvalidToken, 'user does not exist' if @user.nil?

    project_name = request[:name]
    if project_name.blank?
      @project = Project.create!(:name => generate_unique_string, :user => @user)
    else
      @project = Project.find(:first, :conditions => {:name => project_name, :user_id => @user.id})
      @project ||= Project.create!(:name => project_name, :user => @user)
    end

    @resources = []
    for resource in request[:resources]
      @resources << Resource.new(
        resource[:path], 
        resource[:modified_date],
        resource[:content],
        resource[:url],
        @project,
        @user
      )
    end
  end

    # Take an XML document as described at http://code.google.com/p/common-latex-service-interface/wiki/CompileRequestFormat
    # and return a hash containing the parsed data.
    def parse_request(xml_request)
      request = {}

      begin
        compile_request = REXML::Document.new xml_request
      rescue REXML::ParseException
        raise CLSI::ParseError, 'malformed XML'
      end

      compile_tag = compile_request.elements['compile']
      raise CLSI::ParseError, 'no <compile> ... </> tag found' if compile_tag.nil?

      token_tag = compile_tag.elements['token']
      raise CLSI::ParseError, 'no <token> ... </> tag found' if token_tag.nil?
      request[:token] = token_tag.text

      name_tag = compile_tag.elements['name']
      request[:name] = name_tag.nil? ? nil : name_tag.text

      resources_tag = compile_tag.elements['resources']
      raise CLSI::ParseError, 'no <resources> ... </> tag found' if resources_tag.nil?

      request[:root_resource_path] = resources_tag.attributes['root-resource-path']
      request[:root_resource_path] ||= 'main.tex'

      request[:resources] = []
      for resource_tag in resources_tag.elements.to_a
        raise CLSI::ParseError, "unknown tag: #{resource_tag.name}" unless resource_tag.name == 'resource'

        path = resource_tag.attributes['path']
        raise CLSI::ParseError, 'no path attribute found' if path.nil?

        modified_date_text = resource_tag.attributes['modified']
        begin
          modified_date = modified_date_text.nil? ? nil : DateTime.parse(modified_date_text)
        rescue ArgumentError
          raise CLSI::ParseError, 'malformed date'
        end

        url = resource_tag.attributes['url']
        content = resource_tag.text
        if url.blank? and content.blank?
          raise CLSI::ParseError, 'must supply either content or an URL'
        end

        request[:resources] << {
          :path          => path,
          :modified_date => modified_date,
          :url           => url,
          :content       => content
        }
      end

      return request
    end

  def compile
    write_resources_to_disk
    do_compile
    convert_to_output_format
    move_compiled_files_to_public_dir
  ensure
    move_log_files_to_public_dir
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

    run_with_timeout(compile_command)
    run_with_timeout(compile_command)
    run_with_timeout(bibtex_command)
    run_with_timeout(compile_command)
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
    FileUtils.mkdir_p(File.join(SERVER_ROOT_DIR, 'output', self.project.unique_id))
    
    for output_file in output_files(self.output_format)
      output_path = File.join(compile_directory, output_file)
      rel_dest_path = File.join('output', self.project.unique_id, output_file)
      dest_path = File.join(SERVER_ROOT_DIR, rel_dest_path)
      FileUtils.mv(output_path, dest_path)
      @return_files << rel_dest_path
    end
  end
  
  def move_log_files_to_public_dir
    FileUtils.mkdir_p(File.join(SERVER_ROOT_DIR, 'output', self.project.unique_id))
    
    output_log_path = File.join(LATEX_COMPILE_DIR, self.project.unique_id, 'output.log')
    rel_dest_log_path = File.join('output', self.project.unique_id, 'output.log')
    if File.exist?(output_log_path)
      FileUtils.mv(output_log_path, File.join(SERVER_ROOT_DIR, rel_dest_log_path))
      @return_files << rel_dest_log_path
    end
  end
  
  def tex_env_variables
    @tex_env_variables ||= "TEXMFOUTPUT=\"#{compile_directory}\" " +
                           "TEXINPUTS=\"$TEXINPUTS:#{compile_directory}\" " + 
                           "BIBINPUTS=\"#{compile_directory}:$BIBINPUTS\" " + 
                           "BSTINPUTS=\"#{compile_directory}:$BSTINPUTS\" "
  end
  
  def compile_directory_rel_to_chroot
    @compile_directory_rel_to_chroot ||= File.join(LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT, self.project.unique_id)
  end
  
  def compile_directory
    @compile_directory ||= File.join(LATEX_COMPILE_DIR, self.project.unique_id)
  end
  
  def compile_command
    case self.compiler
    when 'pdflatex'
      command = PDFLATEX_COMMAND
    when 'latex'
      command = LATEX_COMMAND
    else
      raise NotImplemented
    end
    return "#{tex_env_variables} #{command} -interaction=batchmode " + 
           "-output-directory=\"#{compile_directory_rel_to_chroot}\" -no-shell-escape " + 
           "-jobname=output #{self.root_resource_path} &> /dev/null"
  end
  
  # Returns a list of output files of the given type. Will raise a CLSI::NoOutputFile if no output
  # files of the given type exist.
  def output_files(type)
    file_name = "output.#{type}"
    output_path = File.join(compile_directory, file_name)
    raise CLSI::NoOutputProduced, 'no compiled documents were produced' unless File.exist?(output_path)
    return [file_name]
  end
  
  def ensure_output_files_exist(type)
    output_files(type)
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
    run_with_timeout(dvipdf_command)
  end
  
  def run_with_timeout(command)
    system(command)
  end
end
