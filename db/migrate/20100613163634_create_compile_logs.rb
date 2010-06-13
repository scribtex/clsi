class CreateCompileLogs < ActiveRecord::Migration
  def self.up
    create_table :compile_logs do |t|
      t.integer    :user_id
      t.integer    :time_taken
      t.boolean    :bibtex_ran,    :default => false
      t.boolean    :makeindex_ran, :default => false
      t.timestamps
    end
    
    drop_table :projects
  end

  def self.down
    drop_table :compile_logs
  end
end
