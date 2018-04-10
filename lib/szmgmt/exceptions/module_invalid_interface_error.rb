module SZMGMT
  module Exceptions
    class ModuleInvalidInterfaceError < StandardError
      def initialize(module_name, method_name)
        super("Loaded application module #{module_name} don't have the correct interface (method #{method_name} missing).")
      end
    end
  end
end
