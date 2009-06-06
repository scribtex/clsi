module WildcardResourceFilesystem
  def self.file?(path)
    project, resource_path = self.extract_project_and_resource_path(path)
    resources = WildcardResource.find(:all, :conditions => {:project_id => project.id})
    for resource in resources
      # Check if wildcard resource path matched provided path
      if File.fnmatch?(resource.path, resource_path)
        url = resource.url.gsub!('%path%', resource_path)
        content = Utilities.get_content_from_url(url)
        print "matched #{resource.path} with #{resource_path}\n"
        print "trying url: #{url}\n"
        if content
          resource.content = content
          resource.save!
          return true
        end
      end
    end
    return false
  end

  def self.directory?(path)
    return true unless path.match('\.[^\/\.]*$') # unless it has an extension
    return false
  end

  def self.read_file(path)
    # We should already have got the content when file? was called
    project, resource_path = self.extract_project_and_resource_path(path)
    resources = WildcardResource.find(:all, :conditions => {:project_id => project.id})
    for resource in resources
      # Check if wildcard resource path matched provided path
      if File.fnmatch?(resource.path, resource_path)
        if resource.content.blank?
          url = resource.url.gsub!('%path%', resource_path)
          return Utilities.get_content_from_url(url)
        else
          return resource.content
        end
      end
    end
    return "" # Shouldn't reach here
  end

  def self.extract_project_and_resource_path(path)
    split_path = path.split('/')
    project_unique_id = split_path[1]
    resource_path = split_path[2..-1].join('/')
    project = Project.find_by_unique_id(project_unique_id)
    raise ActiveRecord::RecordNotFound if project.nil?
    return project, resource_path
  end
end
