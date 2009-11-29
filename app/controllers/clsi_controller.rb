class ClsiController < ApplicationController
  def get_token
    user = User.create!
    render :text => user.token
  end

  def compile
    xml_request = params[:request]
    xml = Builder::XmlMarkup.new(:indent => 4)
    xml.instruct!

    begin
      @compile = Compile.new_from_request(xml_request)
    rescue CLSI::ParseError => e
      render :xml => (xml.compile do
        xml.status('failed parse', :reason => e.message)
      end)
      return
    end
    
    
    render :xml => (xml.compile do
      begin
        @compile.compile
        xml.status('success')
      rescue CLSI::CompileError
        xml.status('compile failed')
      end
      xml.name(@compile.project.name)
      xml.output do
        for file_url in @compile.return_files
          type = file_url[-3,3] # Get file extension
          xml.file(:url => file_url, :type => type)
        end
      end
    end)  
  end
end
