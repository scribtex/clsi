class ClsiController < ApplicationController
  protect_from_forgery :except => [:get_token, :compile]

  def compile
    request.format = :xml
    xml_request = request.raw_post
    
    begin
      @compile = XMLParser.request_to_compile(xml_request)
    rescue CLSI::ParseError => e
      @error_type = e.class.name.demodulize
      @error_message = e.message
      render 'compile_parse_error' and return
    end
  
    @compile.compile
    render :xml => @compile
  end
end
