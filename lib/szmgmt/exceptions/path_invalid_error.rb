module SZMGMT
  module Exceptions
    class PathInvalidError < StandardError
      def initialize(path)
        super("File path invalid. Template or schema on #{path} does not exist.")
      end
    end
  end
end
