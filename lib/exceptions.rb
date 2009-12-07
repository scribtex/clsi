module CLSI
  class ParseError < RuntimeError; end
  class InvalidToken < ParseError; end
  class InvalidPath < ParseError; end
  class UnknownCompiler < ParseError; end
  class ImpossibleOutputFormat < ParseError; end
  
  class CompileError < RuntimeError; end
  class NoOutputProduced < CompileError; end
  class ImpossibleFormatConversion < CompileError; end
end
