module SZMGMT
  module Exceptions
    class APIMethodMissingError < StandardError
      def initialize(method_name)
        super("None of loaded application modules cannot handle #{method_name} method call.")
      end
    end
  end
end
