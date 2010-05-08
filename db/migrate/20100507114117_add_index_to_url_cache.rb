class AddIndexToUrlCache < ActiveRecord::Migration
  def self.up
    add_index :url_caches, :url
  end

  def self.down
  end
end
