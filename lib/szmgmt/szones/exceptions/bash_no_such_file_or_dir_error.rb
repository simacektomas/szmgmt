module SZMGMT
  module SZONES
    module Exceptions
      class BashNoSuchFileorDirError < SZONESError
        def initialize(command, stderr)
          SZMGMT.logger.error("BashNoSuchFileorDirError - No such file or directory '#{command}'.")
          SZMGMT.logger.error("----> (stderr) #{stderr}")
          super(stderr)
        end
      end
    end
  end
end