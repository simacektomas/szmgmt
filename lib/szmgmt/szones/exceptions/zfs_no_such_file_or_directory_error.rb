module SZMGMT
  module SZONES
    module Exceptions
      class ZFSNoSuchFileOrDirectoryError < SZONESError
        def initialize(command, stderr)
          SZMGMT.logger.error("ZFSNoSuchFileOrDirectoryError - No such file or directory exists '#{command}'.")
          SZMGMT.logger.error("----> (stderr) #{stderr}")
          super(stderr)
        end
      end
    end
  end
end