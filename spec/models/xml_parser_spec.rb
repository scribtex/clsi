require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XMLParser do

  describe "bad XML" do
    it "should raise a CLSI::ParseError with malformed XML" do
      lambda{
        XMLParser.request_to_compile('<blah')
      }.should raise_error(CLSI::ParseError, 'malformed XML')
    end

    it "should raise a CLSI::ParseError if there is no compile tag" do
      lambda{
        XMLParser.request_to_compile('<nopile></nopile>')
      }.should raise_error(CLSI::ParseError, 'no <compile> ... </> tag found')      
    end

    it "should raise a CLSI::ParseError if there is no token tag" do
      lambda{
        XMLParser.request_to_compile('<compile></compile>')
      }.should raise_error(CLSI::ParseError, 'no <token> ... </> tag found')      
    end

    it "should raise a CLSI::ParseError if there is no resources tag" do
      lambda{
        XMLParser.request_to_compile(<<-EOS
          <compile>
            <token>abcdefghijklmno</token>
          </compile>
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'no <resources> ... </> tag found')      
    end

    it "should raise a CLSI::ParseError if there is a non resource tag in resources" do
      lambda{
        XMLParser.request_to_compile(<<-EOS
          <compile>
            <token>abcdefghijklmno</token>
            <resources>
              <blah></blah>
            </resources>
          </compile>
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'unknown tag: blah')      
    end

    it "should raise a CLSI::ParseError if there is no path attribute for a resource" do
      lambda{
        XMLParser.request_to_compile(<<-EOS
          <compile>
            <token>abcdefghijklmno</token>
            <resources>
              <resource></resource>
            </resources>
          </compile>
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'no path attribute found')      
    end

    it "should raise a CLSI::ParseError if there is a malformed date" do
      lambda{
        XMLParser.request_to_compile(<<-EOS
          <compile>
            <token>abcdefghijklmno</token>
            <resources>
              <resource path="main.tex" modified="blah"></resource>
            </resources>
          </compile>
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'malformed date')      
    end
  end

  describe 'good XML' do
    it 'should set the token' do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.merge(
          :token => @token = generate_unique_string
        ).to_xml
      )
      @compile.token.should eql @token
    end
    
    it 'should set the name' do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.merge(
          :name => @name = 'Compile Name'
        ).to_xml
      )
      @compile.name.should eql @name
    end
    
    it "should not set the name if it isn't supplied" do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.to_xml
      )
      @compile.name.should be_blank
    end
    
    it 'should set the compiler' do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.merge(
          :compiler => @compiler = 'xetex'
        ).to_xml
      )
      @compile.compiler.should eql @compiler
    end
    
    it 'should set the output format' do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.merge(
          :compiler => @compiler = 'xetex'
        ).to_xml
      )
      @compile.compiler.should eql @compiler
    end
    
    it 'should set the root resource path' do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.merge(
          :root_resource_path => @rrp = 'book.tex'
        ).to_xml
      )
      @compile.root_resource_path.should eql 'book.tex'
    end
    
    it 'should load all resources' do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.merge(
          :resources => [
            @resource1 = {
              :path     => 'book.tex',
              :content  => 'content of book',
            },
            @resource2 = {
              :path     => 'chapter1.tex',
              :url      => 'http://www.example.com/chapter1.tex',
              :modified => DateTime.now
            }
          ]
        ).to_xml
      )
      @compile.resources[0].path.should eql @resource1[:path]
      @compile.resources[0].content.should eql @resource1[:content]
      @compile.resources[0].modified_date.should be_blank
      
      @compile.resources[1].path.should eql @resource2[:path]
      @compile.resources[1].url.should eql @resource2[:url]
      @compile.resources[1].modified_date.to_s.should eql @resource2[:modified].to_s
    end
    
    it 'should read content without CDATA tags' do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.merge(
          :resources => [
            @resource = {
              :path     => 'book.tex',
              :content  => 'content of book',
            }
          ]
        ).to_xml(:with_cdata_tags => false)
      )
      @compile.resources.first.content.should eql @resource[:content]
    end
    
    it 'should read content with CDATA tags' do
      @compile = XMLParser.request_to_compile(
        CLSIRequest.valid_request.merge(
          :resources => [
            @resource = {
              :path     => 'book.tex',
              :content  => 'content of book',
            }
          ]
        ).to_xml(:with_cdata_tags => true)
      )
      @compile.resources.first.content.should eql @resource[:content]
    end
  end
end
