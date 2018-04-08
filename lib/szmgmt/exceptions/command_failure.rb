module SZMGMT
  module Exceptions
    class CommandFailure < StandardError
      def initialize(command, code)
        super("Command #{command} failed with code #{code}.")
      end
    end
  end
end