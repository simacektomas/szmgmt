module SZMGMT
  module Exceptions
    class ModuleNotFoundedError < StandardError
      def initialize(module_name)
        super("Cannot load application module #{module_name} (not implemented).")
      end
    end
  end
end
