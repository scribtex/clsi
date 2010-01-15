xml.instruct!

xml.compile do
  if @status == :success
    xml.status('success')
  else
    xml.status('failure')
    xml.error do
      xml.type @error_type
      xml.message @error_message
    end
  end

  unless @compile.blank?
    xml.name @compile.project.name 
    xml.output do
      for file_url in @compile.return_files
        type = file_url[-3,3] # Get file extension
        xml.file(:url => file_url, :type => type)
      end
    end
  end
end