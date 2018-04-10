module SZMGMT
  module Exceptions
    class JSONParseError < StandardError
      def initialize(path)
        super("Cannot parse JSON file on path #{path}.")
      end
    end
  end
end
