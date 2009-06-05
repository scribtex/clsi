require 'rexml/document'

class Compile
  attr_accessor :user, :project, :root_resource_path, :resources, :status, :return_files

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
        @project
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

  # Compiles resources into a PDF
  def compile
    pre_compile
    do_compile
    post_compile
  end

  # Writes resources to disk
  def pre_compile
    for resource in self.resources.to_a
      resource.write_to_disk
    end
  end

  # Runs LaTeX on files
  def do_compile
    compile_directory = File.join(LATEX_COMPILE_DIR_RELATIVE_TO_CHROOT, self.project.unique_id)
    env_variables = "TEXMFOUTPUT=\"#{compile_directory}\" " +
                    "TEXINPUTS=\"#{compile_directory}:$TEXINPUTS\" " + 
                    "BIBINPUTS=\"#{compile_directory}:$BIBINPUTS\" " + 
                    "BSTINPUTS=\"#{compile_directory}:$BSTINPUTS\" "
    latex_command = "#{env_variables} #{LATEX_COMMAND} -interaction=batchmode " + 
                    "-output-directory=\"#{compile_directory}\" -no-shell-escape " + 
                    "-jobname=output #{self.root_resource_path} > /dev/null"
    bibtex_command = "#{env_variables} #{BIBTEX_COMMAND} " +
                     "#{self.root_resource_path} > /dev/null"

    warn 'warning: latex command has no time out functionality'
    system(latex_command)
    system(latex_command)
    system(bibtex_command)
    system(latex_command)
  end

  # Moves 
  def post_compile
    FileUtils.mkdir_p(File.join(SERVER_ROOT_DIR, 'output', self.project.unique_id))

    output_pdf_path = File.join(LATEX_COMPILE_DIR, self.project.unique_id, 'output.pdf')
    rel_dest_pdf_path = File.join('output', self.project.unique_id, 'output.pdf')
    if File.exist?(output_pdf_path)
      @status = :success
      FileUtils.mv(output_pdf_path, File.join(SERVER_ROOT_DIR, rel_dest_pdf_path))
      @return_files << rel_dest_pdf_path
    else
      @status = :failed
    end

    output_log_path = File.join(LATEX_COMPILE_DIR, self.project.unique_id, 'output.log')
    rel_dest_log_path = File.join('output', self.project.unique_id, 'output.log')
    if File.exist?(output_log_path)
      FileUtils.mv(output_log_path, File.join(SERVER_ROOT_DIR, rel_dest_log_path))
      @return_files << rel_dest_log_path
    end
  end
end
