class UrlCache < ActiveRecord::Base
  validates_presence_of :url, :fetched_at
  
  validates_uniqueness_of :url
  
  def self.get_content_from_url(url, modified_date)
    existing_cache = UrlCache.find(:first, :conditions => {:url => url})
    if existing_cache.nil? or modified_date.nil? or existing_cache.fetched_at < modified_date
      content = Utilities.get_content_from_url(url)
      existing_cache.destroy unless existing_cache.nil?
      UrlCache.create!(:url => url, :content => content, :fetched_at => Time.now)
    else
      content = existing_cache.content
    end
    return content
  end
end
