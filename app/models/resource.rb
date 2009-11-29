class Resource
  attr_reader :path, :modified_date, :url

  def initialize(path, modified_date, content, url, project, user)
    @path          = path
    @modified_date = modified_date
    @content       = content
    @url           = url
    @project       = project
    @user          = user
  end

  # Return the content of this resource. This might come from being passed
  # directly, from the cache or from an URL.
  def content
    unless @url.nil?
      @content ||= UrlCache.get_content_from_url(@url, @modified_date)
    end
    @content
  end

  # Return the path where this resource should be written to for compiling
  def path_to_file_on_disk
    # Must expand any /../s to get absolute directories
    path = File.expand_path(File.join(LATEX_COMPILE_DIR, @project.unique_id, @path))
    compile_directory = File.expand_path(File.join(LATEX_COMPILE_DIR, @project.unique_id))

    # Check that the path begins with the compile directory and is thus inside it
    len = compile_directory.length
    unless path[0,len] == compile_directory
      raise CLSI::InvalidPath, 'path is not inside the compile directory'
    end

    return path
  end

  # Write the contents of this resource to the location provided by the path
  # of the resource
  def write_to_disk
    path = path_to_file_on_disk
    dir_path = File.dirname(path)
    FileUtils.mkdir_p(dir_path)
    File.open(path, 'w') {|f| f.write(self.content)}
  end
end

