class ClsiController < ApplicationController
  protect_from_forgery :except => [:compile]

  def compile
    request.format = "xml" unless params[:format]

    respond_to do |format|
      format.json {
        json_request = request.raw_post
        
        begin
          @request_attributes = JSONParser.parse_request(json_request)
        rescue CLSI::ParseError => e
          @error_type = e.class.name.demodulize
          @error_message = e.message
          render :json => {
            "compile" => {
              "error" => {
                "type"    => e.class.name.demodulize,
                "message" => e.message
              }
            }
          }
          return
        end
      }
      format.all {
        xml_request = request.raw_post
        
        begin
          @request_attributes = XMLParser.parse_request(xml_request)
        rescue CLSI::ParseError => e
          @error_type = e.class.name.demodulize
          @error_message = e.message
          render 'compile_parse_error.xml' and return
        end
      }
    end

    if params[:token] and params[:token].is_a?(String)
      @request_attributes[:token] = params[:token]
    end
    @compile = Compile.new(@request_attributes)
    @compile.unique_id
    if @request_attributes[:asynchronous]
      spawn do
        @compile.compile
      end
    else
      @compile.compile
    end
    
    respond_to do |format|
      format.json {
        render :json => @compile.to_json 
      }
      format.all {
        render :xml => @compile
      }
    end
  end
end
