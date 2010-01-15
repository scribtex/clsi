require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Resource do
  before(:each) do
    @compile = Compile.new
  end

  describe "with content passed directly" do
    before(:each) do
      @resource = Resource.new(
         'chapters/main.tex',
         nil,
         'Test content',
         nil,
         @compile
      )
    end

    it "should write the file to disk in the compile directroy" do
      @resource.write_to_disk
      file_path = File.join(LATEX_COMPILE_DIR, @compile.unique_id, 'chapters/main.tex')
      File.exist?(file_path).should be_true
      File.read(file_path).should eql 'Test content'
      FileUtils.rm_r(File.join(LATEX_COMPILE_DIR, @compile.unique_id))
    end

    it "should return the content passed directly" do
      @resource.content.should eql 'Test content'
    end
  end

  describe "with an URL" do
    before(:each) do
      @begin_test_time = Time.now
      @resource = Resource.new(
         'chapters/main.tex',
         Time.now - 3.days,
         nil,
         'http://www.example.com/main.tex',
         @compile
      )
    end
    
    describe "already in the cache" do
      before do
        UrlCache.create!(:url => @resource.url, :content => (@cached_content = 'Cached Content'),
                         :fetched_at => (@resource.modified_date + 1.day))
      end
      
      it "should return the cached content" do
        Utilities.should_not_receive(:get_content_from_url).with(@resource.url)
        @resource.content.should eql @cached_content
      end
    end
    
    shared_examples_for "an url is fetched and the cache updated" do
      it "should return the content from the URL" do
        @resource.content.should eql @url_content
      end
      
      it "should update the cache with the fetched URL content" do
        cached_url = UrlCache.find(:first, :conditions => {:url => @resource.url})
        cached_url.should_not be_nil
        cached_url.content.should eql @url_content
        # TODO: Stupid time in tests!
        #(cached_url.fetched_at >= @begin_test_time).should be_true
        #(cached_url.fetched_at <= Time.now).should be_true
      end
    end
    
    describe "with an older version in the cache" do
      before do
        Utilities.should_receive(:get_content_from_url).with(@resource.url).and_return(@url_content = 'URL content')
        UrlCache.create!(:url => @resource.url, :content => (@cached_content = 'Cached Content'),
                         :fetched_at => (@resource.modified_date - 1.day))
        @resource.content
      end
      
      it_should_behave_like "an url is fetched and the cache updated"
    end
    
    describe "already in the cache when the resource has no modified date" do
      before do
        Utilities.should_receive(:get_content_from_url).with(@resource.url).and_return(@url_content = 'URL content')
        UrlCache.create!(:url => @resource.url, :content => (@cached_content = 'Cached Content'),
                         :fetched_at => Time.now)
        @resource.instance_variable_set('@modified_date', nil)
        @resource.content
      end

      it_should_behave_like "an url is fetched and the cache updated"
    end
    
    describe "not in the cache" do
      before do
        Utilities.should_receive(:get_content_from_url).with(@resource.url).and_return(@url_content = 'URL content')
        @resource.content # get the lazy loading content from the url
      end

      it_should_behave_like "an url is fetched and the cache updated"
    end
  end

  describe "with a path that tries to break out of the compile directory" do
    before(:each) do
      @resource = Resource.new(
         '../../main.tex',
         nil,
         'Content',
         nil,
         @compile
      )
    end

    it "should raise a CLSI::InvalidPath error when writen to disk" do
      lambda{
        @resource.write_to_disk
      }.should raise_error(CLSI::InvalidPath, 'path is not inside the compile directory')
    end
  end
end
