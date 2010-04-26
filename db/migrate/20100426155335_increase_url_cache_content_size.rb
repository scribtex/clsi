class IncreaseUrlCacheContentSize < ActiveRecord::Migration
  def self.up
    change_column :url_caches, :content, :binary, :limit => 16.megabytes
  end

  def self.down
  end
end
