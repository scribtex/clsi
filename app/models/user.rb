class User < ActiveRecord::Base
  validates_uniqueness_of :token
  validates_presence_of :token

  before_validation_on_create :generate_token
  def generate_token
    self.token = generate_unique_string
  end
end
