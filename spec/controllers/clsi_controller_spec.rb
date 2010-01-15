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

  describe 'successful compile' do
    before do
      @compile = mock('compile', :project => mock('project', :name => 'My Project'))
      XMLParser.should_receive(:request_to_compile).with(@request_xml = '<compile>...</compile>').and_return(@compile)
      @compile.should_receive(:compile)
      @request.env['RAW_POST_DATA'] = @request_xml
      post :compile
    end
    
    it "should set the status to success" do
      assigns[:status].should eql :success
    end
    
    it 'should assign the compile object' do
      assigns[:compile].should eql @compile
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
    
    it 'should set the status to failure' do
      assigns[:status].should eql :failure
    end
    
    it 'should set the error type and message' do
      assigns[:error_type].should eql 'ParseError'
      assigns[:error_message].should eql @error_message
    end
  end

  describe 'unsuccesful compile due to bad LaTeX' do
    before do
      @compile = mock('compile', :project => mock('project', :name => 'My Project'))
      XMLParser.should_receive(:request_to_compile).with(@request_xml = '<compile>...</compile>').and_return(@compile)
      @compile.should_receive(:compile).and_raise(
        CLSI::NoOutputProduced.new(@error_message = 'bad LaTeX!')
      )
      @request.env['RAW_POST_DATA'] = @request_xml
      post :compile
    end
    
    it 'should set the status to failure' do
      assigns[:status].should eql :failure
    end
    
    it 'should set the error type and message' do
      assigns[:error_type].should eql 'NoOutputProduced'
      assigns[:error_message].should eql @error_message
    end
  end
end
