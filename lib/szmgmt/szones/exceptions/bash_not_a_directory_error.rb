module SZMGMT
  module SZONES
    module Exceptions
      class BashNotaDirectoryError < SZONESError
        def initialize(command, stderr)
          SZMGMT.logger.error("BashNotaDirectoryError - Invalid path to directory in command '#{command}'.")
          SZMGMT.logger.error("----> (stderr) #{stderr}")
          super(stderr)
        end
      end
    end
  end
end