require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Compile do
  before(:each) do
    @compile = Compile.new
  end

  describe "parse_request" do
    it "should raise a CLSI::ParseError with malformed XML" do
      lambda{
        @compile.parse_request('<blah')
      }.should raise_error(CLSI::ParseError, 'malformed XML')
    end

    it "should raise a CLSI::ParseError if there is no compile tag" do
      lambda{
        @compile.parse_request('<nopile></nopile>')
      }.should raise_error(CLSI::ParseError, 'no <compile> ... </> tag found')      
    end

    it "should raise a CLSI::ParseError if there is no token tag" do
      lambda{
        @compile.parse_request('<compile></compile>')
      }.should raise_error(CLSI::ParseError, 'no <token> ... </> tag found')      
    end

    it "should raise a CLSI::ParseError if there is no resources tag" do
      lambda{
        @compile.parse_request(<<-EOS
          <compile>
            <token>abcdefghijklmno</token>
          </compile>
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'no <resources> ... </> tag found')      
    end

    it "should raise a CLSI::ParseError if there is a non resource tag in resources" do
      lambda{
        @compile.parse_request(<<-EOS
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
        @compile.parse_request(<<-EOS
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
        @compile.parse_request(<<-EOS
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

    it "should raise a CLSI::ParseError if there is no content for a resource" do
      lambda{
        @compile.parse_request(<<-EOS
          <compile>
            <token>abcdefghijklmno</token>
            <resources>
              <resource path="main.tex" />
            </resources>
          </compile>
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'must supply either content or an URL')      
    end

    it "should set the root resource path to 'main.tex' if none is supplied" do
      request = @compile.parse_request(<<-EOS
        <compile>
          <token>abcdefghijklmno</token>
          <resources></resources>
        </compile>
      EOS
      )
      request[:root_resource_path].should eql 'main.tex'
    end

    it "should return a hash containg the request data" do
      request = @compile.parse_request(<<-EOS
        <compile>
          <token>AdWn34899sKd03S</token>
          <project-id>MyProject</project-id>
          <resources root-resource-path="chapters/main.tex">
            <resource path="chapters/main.tex" modified="2009-03-29T06:00Z">Hello TeX.</resource>
            <resource path="chapters/chapter1.tex" modified="2009-03-29" url="http://www.latexlab.org/getfile/bsoares/23234543543"/>
            <resource path="other/styles/main.sty" modified="2009-03-29">main.sty content</resource>
            <resource path="other/diagrams/diagram1.eps" modified="2009-01-15" url="http://www.latexlab.org/getfile/bsoares/23234543543" />
          </resources>
        </compile>
      EOS
      )
      request[:token].should eql 'AdWn34899sKd03S'
      request[:project_id].should eql 'MyProject'
      request[:root_resource_path].should eql 'chapters/main.tex'
      request[:resources].should include({
        :path          => 'chapters/main.tex',
        :modified_date => DateTime.parse('2009-03-29T06:00Z'),
        :url           => nil,
        :content       => 'Hello TeX.'
      })
      request[:resources].should include({
        :path          => 'chapters/chapter1.tex',
        :modified_date => DateTime.parse('2009-03-29'),
        :url           => 'http://www.latexlab.org/getfile/bsoares/23234543543',
        :content       => nil
      })
      request[:resources].should include({
        :path          => 'other/styles/main.sty',
        :modified_date => DateTime.parse('2009-03-29'),
        :url           => nil,
        :content       => 'main.sty content'
      })
      request[:resources].should include({
        :path          => 'other/diagrams/diagram1.eps',
        :modified_date => DateTime.parse('2009-01-15'),
        :url           => 'http://www.latexlab.org/getfile/bsoares/23234543543',
        :content       => nil
      })
    end
  end
end
