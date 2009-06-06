class CreateWildcardResources < ActiveRecord::Migration
  def self.up
    create_table :wildcard_resources do |t|
      t.string :path
      t.string :url
      t.string :project_id
      t.binary :content, :limit => 4.megabytes
      t.timestamps
    end
  end

  def self.down
    drop_table :wildcard_resources
  end
end
