require 'net/http'
require 'uri'

class Resource
  attr_reader :path, :modified_date, :url

  def initialize(path, modified_date, content, url, project)
    @path = path
    @modified_date = modified_date
    @content = content
    @url = url
    @project = project
  end

  # Return the content of this resource. This might come from being passed
  # directly, from the cache or from an URL.
  def content
    if @content.nil?
      content_from_url
    else
      @content
    end
  end

  # Fetch the content from the URL of this resource
  def content_from_url
    # TODO: This could be made more robust with return value checking,
    # redirect following, specific error catching etc.
    Net::HTTP.get URI.parse(@url)
  rescue
    ""
  end

  # Return the path where this resource should be written to for compiling
  def path_to_file_on_disk
    File.join(LATEX_COMPILE_DIR, @project.unique_id, @path)
  end

  # Write the contents of this resource to the location provided by the path
  # of the resource
  def write_to_disk
    dir_path = File.dirname(path_to_file_on_disk)
    FileUtils.mkdir_p(dir_path)
    File.open(path_to_file_on_disk, 'w') {|f| f.write(self.content)}
  end
end

