module SZMGMT
  module SZONES
    module Exceptions
      class CommandFailureError < StandardError
        def initialize(command_name, exit_code)
          super("Command #{command_name} failed with code #{exit_code}.")
        end
      end
    end
  end
end