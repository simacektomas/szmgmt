module SZMGMT
  module SZONES
    module Exceptions
      class CommandFailureError < SZONESError
        def initialize(command_name, stdout, stderr, exit_code)
          SZMGMT.logger.error("CommandFailureError - Command '#{command_name}' failed with code #{exit_code}.")
          SZMGMT.logger.error("----> (stdout) #{stdout}")
          SZMGMT.logger.error("----> (stderr) #{stderr}")
          super(stderr)
        end
      end
    end
  end
end