require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Resource do
  before(:each) do
    @user = User.create!
    @project = Project.create!(:name => 'Test Project', :user => @user)
    @resource = Resource.new(
       'chapters/main.tex',
       nil,
       'Test content',
       nil,
       @project
    )
  end

  it "should write the file to disk in the compile directroy" do
    @resource.write_to_disk
    file_path = File.join(LATEX_COMPILE_DIR, @project.unique_id, 'chapters/main.tex')
    File.exist?(file_path).should be_true
    File.read(file_path).should eql 'Test content'
  end
end
