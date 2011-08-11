require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe JSONParser do
  describe "bad JSON" do
    it "should raise a CLSI::ParseError with malformed JSON" do
      lambda{
        JSONParser.parse_request('blah')
      }.should raise_error(CLSI::ParseError, 'malformed JSON')
    end
    
    it "should raise a CLSI::ParseError if the top level is not a hash" do
      lambda{
        JSONParser.parse_request("[1,2,3]")
      }.should raise_error(CLSI::ParseError, "top level object should be a hash")
    end

    it "should raise a CLSI::ParseError if there is no compile attribute" do
      lambda{
        JSONParser.parse_request('{"no_compile" : "blah"}')
      }.should raise_error(CLSI::ParseError, 'no compile attribute found')
    end

    it "should raise a CLSI::ParseError if the compile attribute is not a hash" do
      lambda{
        JSONParser.parse_request('{"compile" : 1}')
      }.should raise_error(CLSI::ParseError, 'compile attribute should be a hash')
    end
    
    it "should raise a CLSI::ParseError if the token attribute is not a string" do  
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : 1
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'token attribute should be a string')
    end

    it "should raise a CLSI::ParseError if there is no resources tag" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno"
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'no resources attribute found')
    end

    it "should raise a CLSI::ParseError if the resource tag is not an array" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : "not an array"
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'resources attribute should be an array of resources')
    end

    it "should raise a CLSI::ParseError if there is no path attribute for a resource" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [
                {}
              ]
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'no path attribute found')
    end

    it "should raise a CLSI::ParseError if there is a malformed date" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [
                {
                  "path" : "main.tex",
                  "modified" : "not a date"
                }
              ]
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'malformed date')
    end

    it "should raise a CLSI::ParseError if the url attribute is not a string" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [
                {
                  "path" : "main.tex",
                  "url"  : 1
                }
              ]
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'url attribute should be a string')
    end

    it "should raise a CLSI::ParseError if the content attribute is not a string" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [
                {
                  "path"    : "main.tex",
                  "content" : 1
                }
              ]
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'content attribute should be a string')
    end
    
    it "should raise a CLSI::ParseError unless options attribute is a hash" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [],
              "options"   : "not a hash"
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'options attribute should be a hash')
    end
    
    it "should raise a CLSI::ParseError unless compiler option is a string" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [],
              "options"   : {
                "compiler" : 1
              }
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'compiler attribute should be a string')
    end
    
    it "should raise a CLSI::ParseError unless outputFormat option is a string" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [],
              "options"   : {
                "outputFormat" : 1
              }
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'outputFormat attribute should be a string')
    end
    
    it "should raise a CLSI::ParseError unless asynchronous option is a boolean" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [],
              "options"   : {
                "asynchronous" : "not a boolean"
              }
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'asynchronous attribute should be a boolean')
    end
    
    it "should raise a CLSI::ParseError unless the rootResourcePath attribute is a string" do
      lambda{
        JSONParser.parse_request(<<-EOS
          {
            "compile" : {
              "token" : "abcdefghijklmno",
              "resources" : [],
              "rootResourcePath" : [1,2,3]
            }
          }
        EOS
        )
      }.should raise_error(CLSI::ParseError, 'rootResourcePath attribute should be a string')
    end
  end

  describe 'good JSON' do
    it 'should set the token' do
      attributes = JSONParser.parse_request(
        CLSIRequest.valid_request.merge(
          :token => @token = generate_unique_string
        ).to_json
      )
      attributes[:token].should eql @token
    end
    
    it 'should set the compiler' do
      attributes = JSONParser.parse_request(
        CLSIRequest.valid_request.merge(
          :compiler => @compiler = 'xetex'
        ).to_json
      )
      attributes[:compiler].should eql @compiler
    end
    
    it 'should set the output format' do
      attributes = JSONParser.parse_request(
        CLSIRequest.valid_request.merge(
          :output_format => @output_format = 'dvi'
        ).to_json
      )
      attributes[:output_format].should eql @output_format
    end
    
    it 'should read the asynchronous option' do
      attributes = JSONParser.parse_request(
        CLSIRequest.valid_request.merge(
          :asynchronous => true
        ).to_json
      )
      attributes[:asynchronous].should eql true
    end
    
    it 'should set the root resource path' do
      attributes = JSONParser.parse_request(
        CLSIRequest.valid_request.merge(
          :root_resource_path => @rrp = 'book.tex'
        ).to_json
      )
      attributes[:root_resource_path].should eql 'book.tex'
    end
    
    it 'should load all resources' do
      attributes = JSONParser.parse_request(
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
        ).to_json
      )
      attributes[:resources][0][:path].should eql @resource1[:path]
      attributes[:resources][0][:content].should eql @resource1[:content]
      attributes[:resources][0][:modified_date].should be_blank
      
      attributes[:resources][1][:path].should eql @resource2[:path]
      attributes[:resources][1][:url].should eql @resource2[:url]
      attributes[:resources][1][:modified_date].to_s.should eql @resource2[:modified].to_s
    end
    
    it 'should read the content' do
      attributes = JSONParser.parse_request(
        CLSIRequest.valid_request.merge(
          :resources => [
            @resource = {
              :path     => 'book.tex',
              :content  => 'content of book',
            }
          ]
        ).to_json
      )
      attributes[:resources].first[:content].should eql @resource[:content]
    end
    
    it 'should read the url' do
      attributes = JSONParser.parse_request(
        CLSIRequest.valid_request.merge(
          :resources => [
            @resource = {
              :path => 'book.tex',
              :url  => "http://www.example.com",
            }
          ]
        ).to_json
      )
      attributes[:resources].first[:url].should eql @resource[:url]
    end
  end
end
