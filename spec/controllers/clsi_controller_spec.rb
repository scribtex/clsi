require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ClsiController do
  describe 'successful compile' do
    before do
      @compile = mock('compile', :project => mock('project', :name => 'My Project'))
      XMLParser.should_receive(:request_to_compile).with(@request_xml = '<compile>...</compile>').and_return(@compile)
      @compile.should_receive(:compile)
      @compile.should_receive(:to_xml).and_return(@response_xml = '<response>...</response>')
      @request.env['RAW_POST_DATA'] = @request_xml
      post :compile
    end
    
    it "should return the compile xml" do
      response.body.should eql @response_xml
    end
  end

  describe 'unsuccessful compile due to bad XML' do
    before do
      @compile = mock('compile', :project => mock('project', :name => 'My Project'))
      XMLParser.should_receive(:request_to_compile).with(@request_xml = '<compile>...</compile>').and_raise(
        CLSI::ParseError.new(@error_message = 'bad xml!')
      )
      @compile.should_not_receive(:compile)
      @request.env['RAW_POST_DATA'] = @request_xml
      post :compile
    end
    
    it 'should set the error type and message' do
      assigns[:error_type].should eql 'ParseError'
      assigns[:error_message].should eql @error_message
    end
    
    it 'should render the parse error xml' do
      response.should render_template 'compile_parse_error'
    end
  end
end
