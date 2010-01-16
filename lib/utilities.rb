require 'systemu'
require 'uri'
require 'digest/md5'

def generate_unique_string
  Digest::MD5.hexdigest((Time.now.to_f + rand).to_s)
end

def media_type_from_name(path)
  ext = path[-3,3]
  case ext
  when 'pdf'
    'application/pdf'
  when 'log'
    'text/plain'
  when 'png'
    'image/png'
  else
    ''
  end
end

