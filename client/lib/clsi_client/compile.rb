module CLSI
  class Compile
    attr_accessor :token, :server, :project_id, :resources, :root_resource_path, :compiler, :output_format
    
    def resources 
      @resources ||= []
    end
    
    def to_xml
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.compile do
        xml.token(token)
        xml.project_id(project_id) unless project_id.nil?
        
        if compiler or output_format
          xml.options do
            xml.compiler(compiler) if compiler
            xml.output_format(output_format) if output_format
          end
        end
        
        xml.resources(:root_resource_path => root_resource_path) do
          for resource in resources.to_a
            options = {
              :path => resource.path
            }
            options[:modified] = resource.modified_date unless resource.modified_date.nil?
            if resource.url
              xml.resource(options.merge(:url => resource.url))
            else
              xml.resource(resource.content, options)
            end
          end
        end
      end
    end
  end
end