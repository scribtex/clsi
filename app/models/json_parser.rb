class JSONParser
  # Take some JSON and return a hash containing the parsed data.
  def self.parse_request(json_request)
    request = {}
    
    begin
      data = JSON.parse(json_request)
    rescue JSON::ParserError
      raise CLSI::ParseError, "malformed JSON"
    end
    
    raise CLSI::ParseError, "top level object should be a hash" unless data.is_a?(Hash)

    if data.has_key?("compile")
      compile = data["compile"]
      raise CLSI::ParseError, "compile attribute should be a hash" unless compile.is_a?(Hash)
    else
      raise CLSI::ParseError, "no compile attribute found"
    end
    
    if compile.has_key?("token")
      raise CLSI::ParseError, "token attribute should be a string" unless compile["token"].is_a?(String)
      request[:token] = compile["token"]
    else
      raise CLSI::ParseError, "no token attribute found"
    end
    
    options = compile["options"] || {}
    raise CLSI::ParseError, "options attribute should be a hash" unless options.is_a?(Hash)
    
    if options.has_key?("compiler")
      request[:compiler] = options["compiler"] 
      raise CLSI::ParseError, "compiler attribute should be a string" unless request[:compiler].is_a?(String)
    end
    
    if options.has_key?("outputFormat")
      request[:output_format] = options["outputFormat"]
      raise CLSI::ParseError, "outputFormat attribute should be a string" unless request[:output_format].is_a?(String)
    end
    
    if options.has_key?("asynchronous")
      request[:asynchronous] = options["asynchronous"]
      unless request[:asynchronous] == true or request[:asynchronous] == false
        raise CLSI::ParseError, "asynchronous attribute should be a boolean"
      end
    end
    
    if compile.has_key?("resources")
      resources = compile["resources"]
      raise CLSI::ParseError, "resources attribute should be an array of resources" unless resources.is_a?(Array)
    else
      raise CLSI::ParseError, "no resources attribute found"
    end
    
    if compile.has_key?("rootResourcePath")
      request[:root_resource_path] = compile["rootResourcePath"]
      raise CLSI::ParseError, "rootResourcePath attribute should be a string" unless request[:root_resource_path].is_a?(String)
    end
    
    request[:resources] = []
    for resource in resources
      if resource.has_key?("path")
        path = resource["path"]
      else
        raise CLSI::ParseError, "no path attribute found"
      end
      
      if resource.has_key?("modified")
        begin
          modified_date = DateTime.parse(resource["modified"])
        rescue ArgumentError
          raise CLSI::ParseError, 'malformed date'
        end
      else
        modified_date = nil
      end
      
      if resource.has_key?("url")
        url = resource["url"]
        raise CLSI::ParseError, "url attribute should be a string" unless url.is_a?(String)
      else
        url = nil
      end
      
      if resource.has_key?("content")
        content = resource["content"]
        raise CLSI::ParseError, "content attribute should be a string" unless content.is_a?(String)
      else
        content = nil
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
