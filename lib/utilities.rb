require 'systemu'
require 'uri'

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

module Utilities
  def self.get_content_from_url(url)
    status, stdout, stdin = systemu(['wget', '-O', '-', url])
    return stdout
  end
end
