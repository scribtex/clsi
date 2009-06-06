require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WildcardResourceFilesystem do
  before(:each) do
    @user = User.create!
    @project = Project.create!(:user => @user, :name => 'Test Project')
  end

  describe "extract_project_and_resource_path" do
    it "should find the project based on the first directory being the project's unique id" do
      project, path = WildcardResourceFilesystem.extract_project_and_resource_path(
        "#{@project.unique_id}/resource/path"
      )
      project.should eql @project
      path.should eql 'resource/path' 
    end

    it "should raise an ActiveRecord::RecordNotFound error for a bad project id" do
      lambda{
        WildcardResourceFilesystem.extract_project_and_resource_path(
          "blah/resource/path"
        )
      }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should return a blank path if the path doesn't go past the project id" do
      project, path = WildcardResourceFilesystem.extract_project_and_resource_path(
        "#{@project.unique_id}"
      )
      project.should eql @project
      path.should eql '' 
    end
  end

  describe "directory?" do
    it "should return true if the path doesn't end in a file extension" do
      WildcardResourceFilesystem.directory?('path/to/resource').should be_true
      WildcardResourceFilesystem.directory?('path.to/resource').should be_true
    end

    it "should return false if the path looks like a file by having a file extension" do
      WildcardResourceFilesystem.directory?('path/to/resource.tex').should be_false
      WildcardResourceFilesystem.directory?('path.to/resource.tex').should be_false
    end
  end

  describe "file?" do
    it "should return true if there is wildcard resource matching the pattern and the url returns content" do
      WildcardResource.create!(
        :project => @project,
        :path    => 'chapters/*.tex',
        :url     => 'http://www.example.com/get_file=%path%'
      )
      Utilities.should_receive(:get_content_from_url).with('http://www.example.com/get_file=chapters/chapter1.tex').and_return('test content')
      WildcardResourceFilesystem.file?("#{@project.unique_id}/chapters/chapter1.tex").should be_true
    end

    it "should return false if there is wildcard resource matching the pattern but the url returns no content" do
      WildcardResource.create!(
        :project => @project,
        :path    => 'chapters/*.tex',
        :url     => 'http://www.example.com/get_file=%path%'
      )
      Utilities.should_receive(:get_content_from_url).with('http://www.example.com/get_file=chapters/chapter1.tex').and_return(false)
      WildcardResourceFilesystem.file?("#{@project.unique_id}/chapters/chapter1.tex").should be_false
    end

    it "should return false if there is no wildcard resource matching the pattern" do
      WildcardResource.create!(
        :project => @project,
        :path    => 'chapters/*.tex',
        :url     => 'http://www.example.com/get_file=%path%'
      )
      WildcardResourceFilesystem.file?("#{@project.unique_id}/images/logo.png").should be_false
    end
  end

  describe "read_file" do
    it "should return the content of the matched url when file? has already been called" do
      WildcardResource.create!(
        :project => @project,
        :path    => 'chapters/*.tex',
        :url     => 'http://www.example.com/get_file=%path%'
      )
      Utilities.should_receive(:get_content_from_url).with('http://www.example.com/get_file=chapters/chapter1.tex').and_return('test content')
      WildcardResourceFilesystem.file?("#{@project.unique_id}/chapters/chapter1.tex")
      WildcardResourceFilesystem.read_file("#{@project.unique_id}/chapters/chapter1.tex").should eql 'test content'
    end

    it "should return the content of the matched url when file? has not been called" do
      WildcardResource.create!(
        :project => @project,
        :path    => 'chapters/*.tex',
        :url     => 'http://www.example.com/get_file=%path%'
      )
      Utilities.should_receive(:get_content_from_url).with('http://www.example.com/get_file=chapters/chapter1.tex').and_return('test content')
      WildcardResourceFilesystem.read_file("#{@project.unique_id}/chapters/chapter1.tex").should eql 'test content'
    end

    it "should return a blank string if there is no wildcard resource matching the pattern" do
      WildcardResource.create!(
        :project => @project,
        :path    => 'chapters/*.tex',
        :url     => 'http://www.example.com/get_file=%path%'
      )
      WildcardResourceFilesystem.read_file("#{@project.unique_id}/images/logo.png").should be_blank
    end
  end
end
