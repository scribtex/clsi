module CLSI
  class Resource
    attr_accessor :path, :content, :url, :modified_date
    
    def initialize(options = {})
      for key in options.keys
        self.send("#{key}=", options[key])
      end
    end
  end
end