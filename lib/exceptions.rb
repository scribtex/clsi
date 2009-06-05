module CLSI
  class Error < RuntimeError; end
  class ParseError < Error; end
  class InvalidToken < Error; end
end
