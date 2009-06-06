class ClsiController < ApplicationController
  wsdl_service_name 'Clsi'
  web_service_api ClsiApi

  def getToken
    user = User.create!
    return user.token
  end

  def compile(xml_request)
    xml = Builder::XmlMarkup.new(:indent => 4)

    begin
      @compile = Compile.new_from_request(xml_request)
    rescue => e
      return xml.compile do
        xml.status('failed parse', :reason => e.message)
      end
    end

    @compile.compile
    return xml.compile do
      if @compile.status == :success
        xml.status('success')
      else
        xml.status('failed compile')
      end      
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
