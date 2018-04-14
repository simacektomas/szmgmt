module SZMGMT
  module SZONES
    module Exceptions
      class CommandSyntaxError < SZONESError
        def initialize(command, stderr)
          SZMGMT.logger.error("CommandSyntaxError - Invalid command syntax for command '#{command}'.")
          SZMGMT.logger.error("----> (stderr) #{stderr}")
          super(stderr)
        end
      end
    end
  end
end