require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ClsiController, 'compiling' do
  integrate_views
  
  before do
    @user = User.create!
    @clsi_request = CLSIRequest.new(
      :token => @user.token
    )
  end
  
  shared_examples_for 'with valid latex passed via xml' do
    before do
      @clsi_request.merge!({
        :resources => [
          {
            :path    => 'book.tex',
            :content => File.read(File.join(RESOURCE_FIXTURES_DIR, 'book.tex'))
          },
          {
            :path    => 'chapters/chapter1.tex',
            :content => File.read(File.join(RESOURCE_FIXTURES_DIR, 'chapters/chapter1.tex'))
          },
          {
            :path    => 'chapters/chapter2.tex',
            :content => File.read(File.join(RESOURCE_FIXTURES_DIR, 'chapters/chapter2.tex'))
          },
          {
            :path    => 'bibliography.bib',
            :content => File.read(File.join(RESOURCE_FIXTURES_DIR, 'bibliography.bib'))
          }
        ] 
      })
      @clsi_request[:root_resource_path] = 'book.tex'
      @expected_content = [
        'To take a new paragraph all you need to do is miss out a line.',
        'Here we write about embedding images',
        'Bibliography',
        'The journal of small papers'
      ]
    end
  end
  
  shared_examples_for 'with valid latex passed via urls' do
    before do 
      UrlCache.should download_url(
        'http://test.host/chapter2.tex',
        File.read(File.join(RESOURCE_FIXTURES_DIR, 'chapters/chapter2.tex')),
        anything
      )
      UrlCache.should download_url(
        'http://test.host/chapter1.tex',
        File.read(File.join(RESOURCE_FIXTURES_DIR, 'chapters/chapter1.tex')),
        anything
      )
      UrlCache.should download_url(
        'http://test.host/book.tex',
        File.read(File.join(RESOURCE_FIXTURES_DIR, 'book.tex')),
        anything
      )
      UrlCache.should download_url(
        'http://test.host/bibliography.bib',
        File.read(File.join(RESOURCE_FIXTURES_DIR, 'bibliography.bib')),
        anything
      )
      @clsi_request.merge!({
        :resources => [
          {
            :path    => 'book.tex',
            :url     => 'http://test.host/book.tex'
          },
          {
            :path    => 'chapters/chapter1.tex',
            :url     => 'http://test.host/chapter1.tex'
          },
          {
            :path    => 'chapters/chapter2.tex',
            :url     => 'http://test.host/chapter2.tex'
          },
          {
            :path    => 'bibliography.bib',
            :url     => 'http://test.host/bibliography.bib'
          }
        ] 
      })
      @clsi_request[:root_resource_path] = 'book.tex'
      @expected_content = [
        'To take a new paragraph all you need to do is miss out a line.',
        'Here we write about embedding images',
        'Bibliography',
        'The journal of small papers'
      ]
    end
  end
  
  shared_examples_for 'with pdflatex compiler' do
    before do
      @clsi_request[:compiler] = 'pdflatex'
    end
  end
  
  shared_examples_for 'with latex compiler' do
    before do
      @clsi_request[:compiler] = 'latex'
    end
  end
  
  shared_examples_for 'with pdf output format' do
    before do
      @clsi_request[:output_format] = 'pdf'
    end
  end
  
  shared_examples_for 'with ps output format' do
    before do
      @clsi_request[:output_format] = 'ps'
    end
  end
  
  shared_examples_for 'with dvi output format' do
    before do
      @clsi_request[:output_format] = 'dvi'
    end
  end
  
  shared_examples_for 'send compile request' do
    before do
      @request.env['RAW_POST_DATA'] = @clsi_request.to_xml
      post :compile
      @clsi_response = CLSIResponse.new_from_xml(response.body)
    end
  end
  
  shared_examples_for 'send compile request asynchronously' do
    before do
      @clsi_request[:asynchronous] = true
      @request.env['RAW_POST_DATA'] = @clsi_request.to_xml
      post :compile
      @clsi_response = CLSIResponse.new_from_xml(response.body)
      compile_id = @clsi_response[:compile_id]
      sleep 2
      response_xml = File.read(File.join(SERVER_PUBLIC_DIR, 'output', compile_id, 'response.xml'))
      @clsi_response = CLSIResponse.new_from_xml(response_xml)
    end
  end
  
  shared_examples_for 'receive successful response' do
    it 'should return a successful XML response' do
      @clsi_response[:status].should eql 'success'
    end
  end
  
  shared_examples_for 'log returned' do
    it 'should return the compilation log' do
      log_path_on_disk = @clsi_response[:log_files].first[:url].gsub("http://#{HOST}", SERVER_PUBLIC_DIR)  
      log_content = File.read(log_path_on_disk)
      log_content.should include 'Output written on'
    end
  end
  
  shared_examples_for 'pdf returned' do
    it 'should return a pdf' do
      pdf_path_on_disk = @clsi_response[:output_files].first[:url].gsub("http://#{HOST}", SERVER_PUBLIC_DIR)
      content = read_pdf(pdf_path_on_disk)
      
      for expected_content_fragment in @expected_content do
        content.should include expected_content_fragment
      end
    end
  end
  
  shared_examples_for 'dvi returned' do
    it 'should return a dvi' do
      dvi_path_on_disk = @clsi_response[:output_files].first[:url].gsub("http://#{HOST}", SERVER_PUBLIC_DIR)
      content = read_dvi(dvi_path_on_disk)
      
      for expected_content_fragment in @expected_content do
        content.should include expected_content_fragment
      end
    end
  end
  
  shared_examples_for 'ps returned' do
    it 'should return a ps' do
      ps_path_on_disk = @clsi_response[:output_files].first[:url].gsub("http://#{HOST}", SERVER_PUBLIC_DIR)
      content = read_ps(ps_path_on_disk)
      
      for expected_content_fragment in @expected_content do
        content.should include expected_content_fragment
      end
    end
  end
  
  describe_lots_of_the_form 'with valid latex sent via :send_method with pdflatex compiler and pdf output format',
    :send_method => ['xml', 'urls'],
    :it_should_behave_like => [
      'with valid latex passed via :send_method',
      'with pdflatex compiler',
      'with pdf output format',
      'send compile request',
      'receive successful response',
      'log returned',
      'pdf returned' 
    ],
    :binding => binding
    
  describe_lots_of_the_form 'with valid latex sent via xml with latex compiler and :output_format output format',
    :output_format => ['pdf', 'dvi', 'ps'],
    :it_should_behave_like => [
      'with valid latex passed via xml',
      'with latex compiler',
      'with :output_format output format',
      'send compile request',
      'receive successful response',
      'log returned',
      ':output_format returned' 
    ],
    :binding => binding
    
    
=begin
  # It can't find the user because it's asynchronous?
  describe 'with valid latex sent aysnchronously' do
    it_should_behave_like 'with valid latex passed via xml'
    it_should_behave_like 'with pdflatex compiler'
    it_should_behave_like 'with pdf output format'
    it_should_behave_like 'send compile request asynchronously'
    it_should_behave_like 'receive successful response'
    it_should_behave_like 'log returned'
    it_should_behave_like 'pdf returned' 
  end
=end
end

describe ClsiController, 'with cached URLs' do
  it 'should use the cached URL if provided with an older one'
  
  it 'should use a more up to date URL if provided'
  
  it 'should use the cached URL if not provided with a new date'
end

describe ClsiController, 'with malformed XML' do
  integrate_views
  
  it "should return a ParseError with malformed XML" do
    @request.env['RAW_POST_DATA'] = '<blah'
    post :compile
    @clsi_response = CLSIResponse.new_from_xml(response.body)
    @clsi_response[:status].should eql 'failure'
    @clsi_response[:error_type].should eql 'ParseError'
    @clsi_response[:error_message].should eql 'malformed XML'
  end

  it "should raise a ParseError if there is no compile tag" do
    @request.env['RAW_POST_DATA'] = '<nopile></nopile>'
    post :compile
    @clsi_response = CLSIResponse.new_from_xml(response.body)
    @clsi_response[:status].should eql 'failure'
    @clsi_response[:error_type].should eql 'ParseError'
    @clsi_response[:error_message].should eql 'no <compile> ... </> tag found'  
  end

  it "should raise a ParseError if there is no token tag" do
    @request.env['RAW_POST_DATA'] = '<compile></compile>'
    post :compile
    @clsi_response = CLSIResponse.new_from_xml(response.body)
    @clsi_response[:status].should eql 'failure'
    @clsi_response[:error_type].should eql 'ParseError'
    @clsi_response[:error_message].should eql 'no <token> ... </> tag found'  
  end

  it "should raise a ParseError if there is no resources tag" do
    @request.env['RAW_POST_DATA'] = <<-EOS
      <compile>
        <token>abcdefghijklmno</token>
      </compile>
    EOS
    post :compile
    @clsi_response = CLSIResponse.new_from_xml(response.body)
    @clsi_response[:status].should eql 'failure'
    @clsi_response[:error_type].should eql 'ParseError'
    @clsi_response[:error_message].should eql 'no <resources> ... </> tag found'     
  end

  it "should raise a ParseError if there is a non resource tag in resources" do
    @request.env['RAW_POST_DATA'] = <<-EOS
      <compile>
        <token>abcdefghijklmno</token>
        <resources>
          <blah></blah>
        </resources>
      </compile>
    EOS
      
    post :compile
    @clsi_response = CLSIResponse.new_from_xml(response.body)
    @clsi_response[:status].should eql 'failure'
    @clsi_response[:error_type].should eql 'ParseError'
    @clsi_response[:error_message].should eql 'unknown tag: blah'     
  end

  it "should raise a ParseError if there is no path attribute for a resource" do
    @request.env['RAW_POST_DATA'] = <<-EOS
      <compile>
        <token>abcdefghijklmno</token>
        <resources>
          <resource></resource>
        </resources>
      </compile>
    EOS
      
    post :compile
    @clsi_response = CLSIResponse.new_from_xml(response.body)
    @clsi_response[:status].should eql 'failure'
    @clsi_response[:error_type].should eql 'ParseError'
    @clsi_response[:error_message].should eql 'no path attribute found'     
  end

  it "should raise a ParseError if there is a malformed date" do
    @request.env['RAW_POST_DATA'] = <<-EOS
      <compile>
        <token>abcdefghijklmno</token>
        <resources>
          <resource path="main.tex" modified="blah"></resource>
        </resources>
      </compile>
    EOS
      
    post :compile
    @clsi_response = CLSIResponse.new_from_xml(response.body)
    @clsi_response[:status].should eql 'failure'
    @clsi_response[:error_type].should eql 'ParseError'
    @clsi_response[:error_message].should eql 'malformed date'     
  end
end