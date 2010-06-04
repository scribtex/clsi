require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UrlCache do
  before do
    @time_now = Time.now
    Time.stub!(:now).and_return(@time_now)
  end
   
  shared_examples_for 'with an existing cache' do
    before do
      @existing_cache = UrlCache.create(
        :url => @url = 'http://www.example.com/main.tex',
        :fetched_at => @fetched_at = 3.days.ago
      )
      File.open(@existing_cache.path_to_file_on_disk, 'w') {|f|
        f.write(@existing_content = 'existing content')
      }
    end
  end
  
  describe '#load_from_url with an existing url in the cache' do
    it_should_behave_like 'with an existing cache'
    
    describe 'with a newer modification date' do
      it 'should download the new url' do
        UrlCache.should download_url(@url, 'downloaded content', anything)
        @new_cache = UrlCache.load_from_url(@url, @fetched_at + 1.day)
        File.read(@new_cache.path_to_file_on_disk).should eql 'downloaded content'
        @new_cache.last_accessed.should eql @time_now
      end
    end
    
    describe 'with an older modification date' do
      it 'should return the cached file' do
        UrlCache.should_not_receive(:download_url)
        @new_cache = UrlCache.load_from_url(@url, @fetched_at - 1.day)
        @new_cache.path_to_file_on_disk.should eql @existing_cache.path_to_file_on_disk
        @new_cache.last_accessed.should eql @time_now
      end
    end
    
    describe 'with no modification date' do
      it 'should return the cached file' do
        UrlCache.should_not_receive(:download_url)
        @new_cache = UrlCache.load_from_url(@url, nil)
        @new_cache.path_to_file_on_disk.should eql @existing_cache.path_to_file_on_disk
        @new_cache.last_accessed.should eql @time_now
      end
    end
  end
  
  describe '#load_from_url without an existing url in the cache' do
    it 'should download the new url' do
      @url = 'http://www.example.com/main.tex'
      UrlCache.should download_url(@url, 'downloaded content', anything)
      @new_cache = UrlCache.load_from_url(@url, Time.now)
      File.read(@new_cache.path_to_file_on_disk).should eql 'downloaded content'
      @new_cache.last_accessed.should eql @time_now
    end
  end
  
  describe '#load_from_url unable to download file' do
    it 'should return a blank file' do
      
    end
  end
  
  describe '#destroy' do
    it_should_behave_like 'with an existing cache'
    
    it 'should remove the cache file' do
      @existing_cache.destroy
      File.exist?(@existing_cache.path_to_file_on_disk).should be_false
    end
  end
  
end
