require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

PDFTOTEXT_PATH = 'pdftotext'
PSTOPDF_PATH = 'ps2pdf'
DVITOPDF_PATH = 'dvipdf'

describe ClsiController do
  integrate_views
  
  before do
    @user = User.create!
    @clsi_request = CLSIRequest.new(
      :token              => @user.token,
      :root_resource_path => 'book.tex'
    )
    
    @resource_fixtures_dir = File.expand_path(File.dirname(__FILE__) + '/../fixtures/example_latex')
    @test_host = 'http://test.host'
    @resources = {
      :book => {
        :path    => 'book.tex',
        :content => File.read(File.join(@resource_fixtures_dir, 'book.tex'))
      },
      :book_from_url => {
        :path => 'book.tex',
        :url  => File.join(@test_host, 'book.tex')
      },
      :chapter1 => {
        :path    => 'chapters/chapter1.tex',
        :content => File.read(File.join(@resource_fixtures_dir, 'chapters/chapter1.tex'))
      },
      :chapter1_from_url => {
        :path => 'chapters/chapter1.tex',
        :url  => File.join(@test_host, 'chapters/chapter1.tex')
      },
      :chapter2 => {
        :path    => 'chapters/chapter2.tex',
        :content => File.read(File.join(@resource_fixtures_dir, 'chapters/chapter2.tex'))
      },
      :chapter2_from_url => {
        :path => 'chapters/chapter2.tex',
        :url  => File.join(@test_host, 'chapters/chapter2.tex')
      }
    }
  end
  
  shared_examples_for 'successful compile' do
    it 'should set the status to success and return a log file' do
      @clsi_response = CLSIResponse.new_from_xml(response.body)
      
      @clsi_response[:status].should eql 'success'
      
      log_path_on_disk = @clsi_response[:log_files].first[:url].gsub("http://#{HOST}", SERVER_PUBLIC_DIR)  
      log_content = File.read(log_path_on_disk)
      
      log_content.should include 'Output written on'
    end
  end
  
  shared_examples_for 'successful compile of pdf book' do 
    it 'should return a pdf of the book' do
      @clsi_response = CLSIResponse.new_from_xml(response.body)
    
      pdf_path_on_disk = @clsi_response[:output_files].first[:url].gsub("http://#{HOST}", SERVER_PUBLIC_DIR)
      status, stdout, stdin = systemu([PDFTOTEXT_PATH, pdf_path_on_disk, '-'])
      
      # some content from chapter 1
      stdout.should include 'To take a new paragraph all you need to do is miss out a line.'
      
      # some content from chapter 2
      stdout.should include 'Here we write about embedding images'
    end
    
    it_should_behave_like 'successful compile'
  end
  
  shared_examples_for 'successful compile of postscript book' do 
    it 'should return a postscript file of the book' do
      @clsi_response = CLSIResponse.new_from_xml(response.body)
    
      ps_path_on_disk = @clsi_response[:output_files].first[:url].gsub("http://#{HOST}", SERVER_PUBLIC_DIR)
      pdf_path_on_disk = ps_path_on_disk.gsub('.ps', '.pdf')
      
      systemu([PSTOPDF_PATH, ps_path_on_disk, pdf_path_on_disk])
      
      status, stdout, stdin = systemu([PDFTOTEXT_PATH, pdf_path_on_disk, '-'])
      
      # some content from chapter 1
      stdout.should include 'To take a new paragraph all you need to do is miss out a line.'
      
      # some content from chapter 2
      stdout.should include 'Here we write about embedding images'
    end
    
    it_should_behave_like 'successful compile'
  end
  
  shared_examples_for 'successful compile of dvi book' do 
    it 'should return a postscript file of the book' do
      @clsi_response = CLSIResponse.new_from_xml(response.body)
    
      dvi_path_on_disk = @clsi_response[:output_files].first[:url].gsub("http://#{HOST}", SERVER_PUBLIC_DIR)
      pdf_path_on_disk = dvi_path_on_disk.gsub('.dvi', '.pdf')
      
      systemu([DVITOPDF_PATH, dvi_path_on_disk, pdf_path_on_disk])
      
      status, stdout, stdin = systemu([PDFTOTEXT_PATH, pdf_path_on_disk, '-'])
      
      # some content from chapter 1
      stdout.should include 'To take a new paragraph all you need to do is miss out a line.'
      
      # some content from chapter 2
      stdout.should include 'Here we write about embedding images'
    end
    
    it_should_behave_like 'successful compile'
  end
  
  describe 'compile with content' do
    describe 'sent directly' do
      before do
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [@resources[:book], @resources[:chapter1], @resources[:chapter2]]
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of pdf book'
    end
    
    describe 'sent via urls' do
      before do
        UrlCache.should_receive(:download_url).with(@resources[:chapter2_from_url][:url]).and_return(
          @resources[:chapter2][:content]
        )
        UrlCache.should_receive(:download_url).with(@resources[:chapter1_from_url][:url]).and_return(
          @resources[:chapter1][:content]
        )
        UrlCache.should_receive(:download_url).with(@resources[:book_from_url][:url]).and_return(
          @resources[:book][:content]
        )
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [@resources[:book_from_url], @resources[:chapter1_from_url], @resources[:chapter2_from_url]]
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of pdf book'
    end
    
    describe 'sent via a mixture' do
      before do
        UrlCache.should_receive(:download_url).with(@resources[:chapter2_from_url][:url]).and_return(
          @resources[:chapter2][:content]
        )
        UrlCache.should_receive(:download_url).with(@resources[:book_from_url][:url]).and_return(
          @resources[:book][:content]
        )
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [@resources[:book_from_url], @resources[:chapter1], @resources[:chapter2_from_url]]
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of pdf book'
    end
  end
  
  describe 'caching of urls' do
    describe 'sending the same url again without changing the modification date' do
      before do
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [@resources[:book], @resources[:chapter1], 
            @resources[:chapter2_from_url].merge(:modified => Time.now - 2.days)
          ]
        ).to_xml
      end
      
      it 'should only access the url the first time' do
        UrlCache.should_receive(:download_url).with(
          @resources[:chapter2_from_url][:url]
        ).exactly(1).times.and_return(
          @resources[:chapter2][:content]
        )
        post :compile
        post :compile
      end
    end

    
    describe 'sending the same url again with a newer modification date' do
      it 'should request the url both times' do
        UrlCache.should_receive(:download_url).with(
          @resources[:chapter2_from_url][:url]
        ).exactly(2).times.and_return(
          @resources[:chapter2][:content]
        )
        
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [@resources[:book], @resources[:chapter1], 
            @resources[:chapter2_from_url].merge(:modified => Time.now - 2.days)
          ]
        ).to_xml
        post :compile
        
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [@resources[:book], @resources[:chapter1], 
            @resources[:chapter2_from_url].merge(:modified => Time.now + 2.days)
          ]
        ).to_xml
        post :compile
      end
    end
    
    describe 'sending the same url again without a modification date' do
      it 'should request the url only the first time' do
        UrlCache.should_receive(:download_url).with(
          @resources[:chapter2_from_url][:url]
        ).exactly(1).times.and_return(
          @resources[:chapter2][:content]
        )
        
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [@resources[:book], @resources[:chapter1], 
            @resources[:chapter2_from_url].merge(:modified => Time.now - 2.days)
          ]
        ).to_xml
        post :compile
        
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [@resources[:book], @resources[:chapter1], 
            @resources[:chapter2_from_url]
          ]
        ).to_xml
        post :compile
      end
    end
  end
  
  describe 'different compilers and output formats' do
    describe 'pdflatex outputting pdf' do
      before do
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources     => [@resources[:book], @resources[:chapter1], @resources[:chapter2]],
          :compiler      => 'pdflatex',
          :output_format => 'pdf'
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of pdf book'
    end
    
    describe 'latex outputting pdf' do
      before do
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources     => [@resources[:book], @resources[:chapter1], @resources[:chapter2]],
          :compiler      => 'latex',
          :output_format => 'pdf'
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of pdf book'
    end
    
    describe 'latex outputting postscript' do
      before do
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources     => [@resources[:book], @resources[:chapter1], @resources[:chapter2]],
          :compiler      => 'latex',
          :output_format => 'ps'
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of postscript book'
    end
    
    describe 'latex outputting dvi' do
      before do
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources     => [@resources[:book], @resources[:chapter1], @resources[:chapter2]],
          :compiler      => 'latex',
          :output_format => 'dvi'
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of dvi book'
    end
  end
  
  describe 'different root resource paths' do
    describe 'no root resource specified' do
      before do
        @clsi_request.delete(:root_resource_path)
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [
            @resources[:book].merge(
              :path => 'main.tex'
            ), 
            @resources[:chapter1], @resources[:chapter2]
          ]
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of pdf book'
    end
    
    describe 'root resource specified' do
      before do
        @clsi_request[:root_resource_path] = 'book.tex'
        @request.env['RAW_POST_DATA'] = @clsi_request.merge(
          :resources => [
            @resources[:book].merge(
              :path => 'book.tex'
            ), 
            @resources[:chapter1], @resources[:chapter2]
          ]
        ).to_xml
        post :compile
      end
      
      it_should_behave_like 'successful compile of pdf book'
    end
  end
  
  describe 'requests with errors' do
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
end
