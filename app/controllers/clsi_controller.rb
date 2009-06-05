class ClsiController < ApplicationController
  wsdl_service_name 'Clsi'
  web_service_api ClsiApi

  def compile(xml)
    warn 'warning: need to handle errors in compile much better'
    begin
      @compile = Compile.new_from_request(xml)
    rescue
      render :text => 'Failed' and return
    end
    @compile.compile
   
    xml = Builder::XmlMarkup.new(:indent => 4)
    return xml.compile do
      xml.name(@compile.project.name)
      xml.output do
        for file_url in @compile.return_files
          type = file_url[-3,3] # Get file extension
          xml.file(:url => file_url, :type => type)
        end
      end
    end
    
  end
end
