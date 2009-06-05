require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Project do
  it "should generate a unique id before being created" do
    project = Project.create!(:name => nil, :user => User.create!)
    project.unique_id.should_not be_nil
  end
end
