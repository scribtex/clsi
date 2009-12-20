class ClsiController < ApplicationController
  protect_from_forgery :except => [:get_token, :compile]
  
  def get_token
    user = User.create!
    render :text => user.token
  end

  def compile
    xml_request = request.env['RAW_POST_DATA']
    xml = Builder::XmlMarkup.new(:indent => 4)
    xml.instruct!

    begin
      @compile = Compile.new_from_request(xml_request)
    rescue CLSI::ParseError => e
      render :xml => (xml.compile do
        xml.status('failure')
        xml.error(e.class.name.demodulize, :message => e.message)
      end)
      return
    end
    
    render :xml => (xml.compile do
      begin
        @compile.compile
        xml.status('success')
      rescue CLSI::CompileError => e
        xml.status('failure')
        xml.error(e.class.name.demodulize, :message => e.message)
      end
      xml.name(@compile.project.name)
      xml.output do
        for file_url in @compile.return_files
          type = media_type_from_name(file_url)
          xml.file(:url => File.join('http://', request.host_with_port, file_url), :type => type)
        end
      end
    end)  
  end
end
