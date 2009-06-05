class Resource
  attr_reader :path, :modified_date, :content, :url

  def initialize(path, modified_date, content, url, project)
    @path = path
    @modified_date = modified_date
    @content = content
    @url = url
    @project = project
  end
end
