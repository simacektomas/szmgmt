module SZMGMT
  module SZONES
    module Exceptions
      class CommandFailureError < StandardError
        def initialize(command)
          super("Command #{command.command} failed with code #{command.exit_code}.")
        end
      end
    end
  end
end