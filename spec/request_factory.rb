class CLSIRequest < HashWithIndifferentAccess
  
  def self.valid_request
    CLSIRequest.new(
      :token => generate_unique_string
    )
  end
  
  def to_xml(options = {})
    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!
    
    xml.compile do
      xml.token self[:token]
      xml.name  self[:name]  unless self[:name].blank?
      unless self[:compiler].blank? and self[:output_format].blank?
        xml.options do
          xml.compiler self[:compiler] unless self[:compiler].blank?
          xml.tag!("output-format", self[:output_format]) unless self[:output_format].blank?
        end
      end
      
      resource_options = {}
      resource_options.merge!("root-resource-path" => self[:root_resource_path]) unless self[:root_resource_path].blank?
      xml.resources(resource_options) do
        for resource in self[:resources].to_a do
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
