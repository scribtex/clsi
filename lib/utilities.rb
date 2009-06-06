require 'net/http'
require 'uri'

def generate_unique_string
  Digest::MD5.hexdigest((Time.now.to_f + rand).to_s)
end

module Utilities
  def self.get_content_from_url(url)
    # TODO: This could be made more robust with return value checking,
    # redirect following, specific error catching etc.
    def self.get_response_from_url(url)
      url = URI.parse(url)
      res = Net::HTTP.start(url.host, url.port) {|http|
        url.path = '/' if url.path.blank?
        http.get(url.path)
      }
      return res
    end

    res = self.get_response_from_url(url)
    if res.header['location']
      res = get_response_from_url(res.header['location'])
    end

    if res.is_a?(Net::HTTPSuccess)
      return res.body
    else
      return false
    end
  rescue SocketError
    false
  end
end
