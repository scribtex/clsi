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
    unless @compile.output_files.empty?
      xml.output do
        for file in @compile.output_files
          xml.file(:url => file.url, :type => file.type, :mimetype => file.mimetype)
        end
      end
    end
    
    unless @compile.log_files.empty?
      xml.logs do
        for file in @compile.log_files
          xml.file(:url => file.url, :type => file.type, :mimetype => file.mimetype)
        end
      end
    end
  end
end