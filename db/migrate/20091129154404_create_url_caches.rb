class CreateUrlCaches < ActiveRecord::Migration
  def self.up
    create_table :url_caches do |t|
      t.string   :url,        :null => false
      t.datetime :fetched_at, :null => false
      t.binary   :content
    end
  end

  def self.down
    drop_table :url_caches
  end
end
