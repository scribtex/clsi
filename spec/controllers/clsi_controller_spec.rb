require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ClsiController do
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
