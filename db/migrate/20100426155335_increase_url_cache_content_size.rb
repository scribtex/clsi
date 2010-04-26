class IncreaseUrlCacheContentSize < ActiveRecord::Migration
  def self.up
    change_column :url_caches, :content, :binary, :limit => 10.megabytes
  end

  def self.down
  end
end
