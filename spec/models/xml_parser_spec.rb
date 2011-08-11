require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe XMLParser do

  describe "bad XML" do
    it "should raise a CLSI::ParseError with malformed XML" do
      lambda{
        XMLParser.parse_request('<blah')
      }.should raise_error(CLSI::ParseError, 'malformed XML')
    end

    it "should raise a CLSI::ParseError if there is no compile tag" do
      lambda{
        XMLParser.parse_request('<nopile></nopile>')
      }.should raise_error(CLSI::ParseError, 'no <compile> ... </> tag found')      
    end

    it "should raise a CLSI::ParseError if there is no resources tag" do
      lambda{
        XMLParser.parse_request(<<-EOS
          <compile>
            <token>abcdefghijklmno</token>
          </compile>
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'no <resources> ... </> tag found')      
    end

    it "should raise a CLSI::ParseError if there is a non resource tag in resources" do
      lambda{
        XMLParser.parse_request(<<-EOS
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
        XMLParser.parse_request(<<-EOS
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
        XMLParser.parse_request(<<-EOS
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
      attributes = XMLParser.parse_request(
        CLSIRequest.valid_request.merge(
          :token => @token = generate_unique_string
        ).to_xml
      )
      attributes[:token].should eql @token
    end
    
    it 'should set the compiler' do
      attributes = XMLParser.parse_request(
        CLSIRequest.valid_request.merge(
          :compiler => @compiler = 'xetex'
        ).to_xml
      )
      attributes[:compiler].should eql @compiler
    end
    
    it 'should set the output format' do
      attributes = XMLParser.parse_request(
        CLSIRequest.valid_request.merge(
          :output_format => @output_format = 'dvi'
        ).to_xml
      )
      attributes[:output_format].should eql @output_format
    end
    
    it 'should read the asynchronous option' do
      attributes = XMLParser.parse_request(
        CLSIRequest.valid_request.merge(
          :asynchronous => true
        ).to_xml
      )
      attributes[:asynchronous].should eql true
    end
    
    it 'should set the root resource path' do
      attributes = XMLParser.parse_request(
        CLSIRequest.valid_request.merge(
          :root_resource_path => @rrp = 'book.tex'
        ).to_xml
      )
      attributes[:root_resource_path].should eql 'book.tex'
    end
    
    it 'should load all resources' do
      attributes = XMLParser.parse_request(
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
      attributes[:resources][0][:path].should eql @resource1[:path]
      attributes[:resources][0][:content].should eql @resource1[:content]
      attributes[:resources][0][:modified_date].should be_blank
      
      attributes[:resources][1][:path].should eql @resource2[:path]
      attributes[:resources][1][:url].should eql @resource2[:url]
      attributes[:resources][1][:modified_date].to_s.should eql @resource2[:modified].to_s
    end
    
    it 'should read content without CDATA tags' do
      attributes = XMLParser.parse_request(
        CLSIRequest.valid_request.merge(
          :resources => [
            @resource = {
              :path     => 'book.tex',
              :content  => 'content of book',
            }
          ]
        ).to_xml(:with_cdata_tags => false)
      )
      attributes[:resources].first[:content].should eql @resource[:content]
    end
    
    it 'should read content with CDATA tags' do
      attributes = XMLParser.parse_request(
        CLSIRequest.valid_request.merge(
          :resources => [
            @resource = {
              :path     => 'book.tex',
              :content  => 'content of book',
            }
          ]
        ).to_xml(:with_cdata_tags => true)
      )
      attributes[:resources].first[:content].should eql @resource[:content]
    end
  end
end
