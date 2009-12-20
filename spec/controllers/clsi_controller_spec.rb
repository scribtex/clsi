require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ClsiController do
  describe 'getToken' do
    it "should return a token and create a user with that token" do
      get :get_token
      token = response.body
      token.length.should eql 32
      user = User.find_by_token(token)
      user.should_not be_nil
    end
  end

  describe 'compile' do
    it "should return a list of compiled files for a successful compile" do
      @compile = mock('compile', :project => mock('project', :name => 'My Project'))
      @compile.stub!(:compile)
      @compile.stub!(:status).and_return(:success)
      @compile.stub!(:return_files).and_return(['output/output.pdf', 'output/output.log'])
      Compile.should_receive('new_from_request').with('request_xml').and_return(@compile)
      @request.env['RAW_POST_DATA'] = 'request_xml'
      result = post :compile
      result = response.body
      
      parser = REXML::Document.new result
      parser.elements['compile'].elements['status'].text.should eql 'success'
      parser.elements['compile'].elements['name'].text.should eql 'My Project'

      file1 = parser.elements['compile'].elements['output'].elements[1]
      file1.name.should eql 'file'
      file1.attributes['type'].should eql 'application/pdf'
      file1.attributes['url'].should eql 'http://test.host/output/output.pdf'

      file2 = parser.elements['compile'].elements['output'].elements[2]
      file2.name.should eql 'file'
      file2.attributes['type'].should eql 'text/plain'
      file2.attributes['url'].should eql 'http://test.host/output/output.log'
    end

    it "should return the log file for an unsuccessful compile" do
      @compile = mock('compile', :project => mock('project', :name => 'My Project'))
      @compile.stub!(:compile).and_raise(CLSI::NoOutputProduced.new('no compiled documents were produced'))
      @compile.stub!(:status).and_return(:failed)
      @compile.stub!(:return_files).and_return(['output/output.log'])

      Compile.should_receive('new_from_request').with('request_xml').and_return(@compile)
      @request.env['RAW_POST_DATA'] = 'request_xml'
      result = post :compile
      result = response.body
      
      parser = REXML::Document.new result
      parser.elements['compile'].elements['status'].text.should eql 'failure'
      parser.elements['compile'].elements['error'].text.should eql 'NoOutputProduced'
      parser.elements['compile'].elements['error'].attributes['message'].should eql 'no compiled documents were produced'
      parser.elements['compile'].elements['name'].text.should eql 'My Project'

      file = parser.elements['compile'].elements['output'].elements[1]
      file.name.should eql 'file'
      file.attributes['type'].should eql 'text/plain'
      file.attributes['url'].should eql 'http://test.host/output/output.log'
    end

    it "should return an error message for an unsuccessful compile" do
      @compile = mock('compile', :project => mock('project', :name => 'My Project'))
      Compile.should_receive('new_from_request').with('bad_xml').and_raise(CLSI::ParseError.new('malformed XML'))
      @request.env['RAW_POST_DATA'] = 'bad_xml'
      result = post :compile
      result = response.body
      
      parser = REXML::Document.new result
      parser.elements['compile'].elements['status'].text.should eql 'failure'
      parser.elements['compile'].elements['error'].text.should eql 'ParseError'
      parser.elements['compile'].elements['error'].attributes['message'].should eql 'malformed XML'
    end
  end
end
