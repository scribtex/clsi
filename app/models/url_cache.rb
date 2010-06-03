class UrlCache < ActiveRecord::Base
  validates_presence_of :url, :fetched_at
  
  validates_uniqueness_of :url
  
  def path_to_file_on_disk
    File.join(CACHE_DIR, Digest::MD5.hexdigest(self.url))
  end
  
  def self.load_from_url(url, modified_date)
    cache = UrlCache.find_by_url(url)
    
    if cache.nil? 
      cache = UrlCache.new(:url => url)
      cache.download! # also saves
    elsif (not modified_date.nil? and cache.fetched_at < modified_date)
      cache.download!
    end
    
    return cache
  end
  
  def download!
    status, stdout, stderr = systemu(['wget', '-O', self.path_to_file_on_disk, self.url])
    FileUtils.touch(self.path_to_file_on_disk)
    self.fetched_at = Time.now
    self.save!
  end
end
