class WildcardResource < ActiveRecord::Base
  belongs_to :project
  validates_presence_of :project, :path, :url
end
