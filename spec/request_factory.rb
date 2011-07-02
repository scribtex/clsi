class CLSIRequest < HashWithIndifferentAccess
  
  def self.valid_request
    CLSIRequest.new(
      :token     => generate_unique_string,
      :resources => []
    )
  end
  
  def to_json
    options = {}
    options[:outputFormat] = self[:output_format] if self.has_key?(:output_format)
    options[:compiler] = self[:compiler] if self.has_key?(:compiler)
    options[:asynchronous] = self[:asynchronous] if self.has_key?(:asynchronous)
  
    hash = {
      "token"     => self[:token],
      "resources" => self[:resources],
      "options"   => options
    }
    
    hash["rootResourcePath"] = self[:root_resource_path] if self.has_key?(:root_resource_path)

    
    return ({"compile" => hash}).to_json
  end
  
  def to_xml(options = {:with_cdata_tags => true})
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!
    
    xml.compile do
      xml.token self[:token]
      xml.name  self[:name]  unless self[:name].blank?
      xml.options do
        xml.compiler self[:compiler] unless self[:compiler].blank?
        xml.tag!("output-format", self[:output_format]) unless self[:output_format].blank?
        xml.asynchronous 'true' if self[:asynchronous]
      end
      
      resource_options = {}
      resource_options.merge!("root-resource-path" => self[:root_resource_path]) unless self[:root_resource_path].blank?
      xml.resources(resource_options) do
        for resource in self[:resources].to_a do
          resource = resource.dup
          content = resource.delete(:content)
          xml.resource(resource) do
            if options[:with_cdata_tags]
              xml.cdata! content unless content.blank?
            else
              xml.text!  content unless content.blank?
            end
          end
        end
      end
    end
  end
  
  alias :old_merge :merge
  def merge(other)
    CLSIRequest.new(self.old_merge(other))
  end
  
end

class CLSIResponse < HashWithIndifferentAccess
  
  def self.new_from_xml(xml)
    response = self.new
    response_xml = REXML::Document.new xml
    compile_tag = response_xml.elements['compile']
    
    response[:status] = compile_tag.elements['status'].text
    response[:compile_id] = compile_tag.elements['compile_id'].text unless compile_tag.elements['compile_id'].nil?
    
    if compile_tag.elements['error']
      response[:error_type] = compile_tag.elements['error'].elements['type'].text
      response[:error_message] = compile_tag.elements['error'].elements['message'].text
    end
    
    if compile_tag.elements['output']
      response[:output_files] = []
      for file_tag in compile_tag.elements['output'].elements.to_a
        response[:output_files] << {
          :url      => file_tag.attributes['url'],
          :type     => file_tag.attributes['type'],
          :mimetype => file_tag.attributes['mimetype']
        }
      end
    end
    
    if compile_tag.elements['logs']
      response[:log_files] = []
      for file_tag in compile_tag.elements['logs'].elements.to_a
        response[:log_files] << {
          :url      => file_tag.attributes['url'],
          :type     => file_tag.attributes['type'],
          :mimetype => file_tag.attributes['mimetype']
        }
      end
    end
    
    return response
  end
  
end
