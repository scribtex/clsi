require 'rexml/document'

class Compile
  attr_reader :user, :project_id, :root_resource_path

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
    token = request[:token]
    @project_id = request[:project_id]
    @root_resource_path = request[:root_resource_path]

    @user = User.find_by_token(token)
    raise CLSI::InvalidToken, 'user does not exist' if @user.nil?
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
    
    project_id_tag = compile_tag.elements['project-id']
    request[:project_id] = project_id_tag.nil? ? nil : project_id_tag.text

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
end
