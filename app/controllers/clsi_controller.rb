class ClsiController < ApplicationController
  protect_from_forgery :except => [:get_token, :compile]
  
  def get_token
    user = User.create!
    render :text => user.token
  end

  def compile
    request.format = :xml
    xml_request = request.env['RAW_POST_DATA']
    
    @compile = XMLParser.request_to_compile(xml_request)
    @compile.compile
    @status = :success
  rescue CLSI::ParseError, CLSI::CompileError => e
    @status = :failure
    @error_type = e.class.name.demodulize
    @error_message = e.message
  end
end
