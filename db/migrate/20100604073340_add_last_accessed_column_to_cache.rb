class AddLastAccessedColumnToCache < ActiveRecord::Migration
  def self.up
    add_column    :url_caches, :last_accessed, :datetime
    remove_column :url_caches, :content
  end

  def self.down
  end
end
