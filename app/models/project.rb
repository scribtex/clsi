class Project < ActiveRecord::Base
  belongs_to :user

  validates_uniqueness_of :unique_id
  validates_presence_of :unique_id, :user

  before_validation_on_create :generate_unique_id
  def generate_unique_id
    self.unique_id = generate_unique_string
  end
end
