module SZMGMT
  module Exceptions
    class TemplateSyntaxError < StandardError
      def initialize(path)
        super("Syntax error. Template or schema on path '#{path}' cannot be parsed. SyntaxError.")
      end
    end
  end
end
