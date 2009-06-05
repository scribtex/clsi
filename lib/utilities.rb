def generate_unique_string
  Digest::MD5.hexdigest((Time.now.to_f + rand).to_s)
end
