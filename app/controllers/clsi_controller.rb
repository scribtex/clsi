class ClsiController < ApplicationController
  protect_from_forgery :except => [:get_token, :compile]

  def compile
    request.format = :xml
    xml_request = request.raw_post
    
    begin
      request_attributes = XMLParser.parse_request(xml_request)
    rescue CLSI::ParseError => e
      @error_type = e.class.name.demodulize
      @error_message = e.message
      render 'compile_parse_error' and return
    end
  
    @compile = Compile.new(request_attributes)
    @compile.unique_id
    if request_attributes[:asynchronous]
      spawn do
        @compile.compile
      end
    else
      @compile.compile
    end
    render :xml => @compile
  end
end
