require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Resource do
  before do
    @compile = Compile.new
  end

  describe "with content passed directly" do
    before do
      @resource = Resource.new(
         'chapters/main.tex',
         nil,
         'Test content',
         nil,
         @compile
      )
    end

    it "should write the file to disk in the compile directroy" do
      @resource.write_to_disk
      file_path = File.join(LATEX_COMPILE_DIR, @compile.unique_id, 'chapters/main.tex')
      File.exist?(file_path).should be_true
      File.read(file_path).should eql 'Test content'
      FileUtils.rm_r(File.join(LATEX_COMPILE_DIR, @compile.unique_id))
    end

    it "should return the content passed directly" do
      @resource.content.should eql 'Test content'
    end
  end

  describe 'with an URL' do
    before do
      @resource = Resource.new( 
        'chapters/main.tex',
        @modified_date = 2.days.ago,
        nil,
        @url = 'http://www.example.com/main.tex',
        @compile
      )
      
      @cache = UrlCache.create!(
        :url => @url,
        :fetched_at => @modified_date + 1.day
      )
      File.open(@cache.path_to_file_on_disk, 'w') {|f|
        f.write(@content = 'URL content')
      }
    end
    
    it 'should copy the downloaded content to the required location' do
      @resource.write_to_disk
      File.read(@resource.path_to_file_on_disk).should eql @content
    end
  end

  describe "with a path that tries to break out of the compile directory" do
    before(:each) do
      @resource = Resource.new(
         '../../main.tex',
         nil,
         'Content',
         nil,
         @compile
      )
    end

    it "should raise a CLSI::InvalidPath error when writen to disk" do
      lambda{
        @resource.write_to_disk
      }.should raise_error(CLSI::InvalidPath, 'path is not inside the compile directory')
    end
  end
end
