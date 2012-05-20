class UrlCache < ActiveRecord::Base
  validates_presence_of :url, :fetched_at
  
  validates_uniqueness_of :url
  
  after_destroy :remove_cache_file
  
  class << self
    def load_from_url(url, modified_date)
      cache = UrlCache.find_by_url(url)
    
      if cache.nil? 
        cache = UrlCache.new(:url => url)
        cache.download!
      elsif (not modified_date.nil? and cache.fetched_at < modified_date)
        cache.download!
      end
      cache.fetched_at = modified_date
      cache.last_accessed = Time.now
      cache.save

      return cache
    end
  
    def download_url(url, to_path)
      status, stdout, stderr = systemu(['wget', '-O', to_path, url])
      FileUtils.touch(to_path)
      return true
    end
    
    def path_from_url(url)
      File.join(CACHE_DIR, Digest::MD5.hexdigest(url))
    end
  end
  
  def path_to_file_on_disk
    UrlCache.path_from_url(self.url)
  end
  
  def download!
    FileUtils.mkdir_p(File.dirname(self.path_to_file_on_disk))
    UrlCache.download_url(self.url, self.path_to_file_on_disk)
  end
  
  def remove_cache_file
    FileUtils.rm(self.path_to_file_on_disk) if File.exist?(self.path_to_file_on_disk)
  end
end
