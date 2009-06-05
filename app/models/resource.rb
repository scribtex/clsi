class Resource
  attr_reader :path, :modified_date, :url

  def initialize(path, modified_date, content, url, project)
    @path = path
    @modified_date = modified_date
    @content = content
    @url = url
    @project = project
  end

  def content
    if @content.nil?
      raise NotImplementedError, 'cannot get content from URL'
    else
      @content
    end
  end

  def path_to_file_on_disk
    File.join(LATEX_COMPILE_DIR, @project.unique_id, @path)
  end

  def write_to_disk
    dir_path = File.dirname(path_to_file_on_disk)
    FileUtils.mkdir_p(dir_path)
    File.open(path_to_file_on_disk, 'w') {|f| f.write(self.content)}
  end
end

