module CLSI
  class ParseError < RuntimeError; end
  
  class CompileError < RuntimeError; end
  class InvalidToken < CompileError; end
  class UnknownCompiler < CompileError; end
  class ImpossibleOutputFormat < CompileError; end
  class InvalidPath < CompileError; end
  class NoOutputProduced < CompileError; end
  class ImpossibleFormatConversion < CompileError; end
  class Timeout < CompileError; end
end
