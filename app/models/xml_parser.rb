class XMLParser
  # Take an XML document as described at http://code.google.com/p/common-latex-service-interface/wiki/CompileRequestFormat
  # and return a hash containing the parsed data.
  def self.parse_request(xml_request)
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

    options_tag = compile_tag.elements['options']
    unless options_tag.nil?
      compiler_tag = options_tag.elements['compiler']
      request[:compiler] = compiler_tag.text unless compiler_tag.nil?
      output_format_tag = options_tag.elements['output-format']
      request[:output_format] = output_format_tag.text unless output_format_tag.nil?
      asynchronous_tag = options_tag.elements['asynchronous']
      request[:asynchronous] = ['true', '1'].include?(asynchronous_tag.text) unless asynchronous_tag.nil?
    end

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
      if resource_tag.cdatas.empty?
        content = resource_tag.text.to_s.strip
      else
        content = resource_tag.cdatas.join
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