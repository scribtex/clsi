class UrlCache < ActiveRecord::Base
  validates_presence_of :url, :fetched_at
  
  validates_uniqueness_of :url
  
  def self.get_content_from_url(url, modified_date)
    existing_cache = UrlCache.find(:first, :conditions => {:url => url})
    
    if existing_cache.nil? or (not modified_date.nil? and existing_cache.fetched_at < modified_date)
      # Refresh the cache if it doesn't exist or if the resource has a newer modification date
      # If a modification date is not provided the cache will never be refreshed
      content = UrlCache.download_url(url)
      existing_cache.destroy unless existing_cache.nil?
      UrlCache.create!(:url => url, :content => content, :fetched_at => Time.now)
    else
      content = existing_cache.content
    end
    return content
  end
  
  def self.download_url(url)
    status, stdout, stdin = systemu(['wget', '-O', '-', url])
    return stdout
  end
end
