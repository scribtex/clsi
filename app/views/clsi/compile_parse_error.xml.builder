xml.instruct!

xml.compile do
  xml.status('failure')
  xml.error do
    xml.type @error_type
    xml.message @error_message
  end
end