class OutputFile
  attr_accessor :path
  attr_reader :type, :mimetype
  
  def initialize(attributes = {})
    for name, value in attributes
      self.send("#{name}=", value)
    end
  end
  
  def type
    path.split('.').last
  end
  
  def mimetype
    case type
    when 'pdf'
      'application/pdf'
    when 'log'
      'text/plain'
    when 'dvi'
      'application/x-dvi'
    when 'ps'
      'application/postscript'
    when 'png'
      'image/png'
    end
  end
  
  def url
    File.join("http://#{HOST}", self.path)
  end
  
  def ==(other)
    other.path == self.path
  end
  
end