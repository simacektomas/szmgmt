module SZMGMT
  module SZONES
    module Exceptions
      class ZFSNoSuchFilesystemError < SZONESError
        def initialize(command, stderr)
          SZMGMT.logger.error("ZFSNoSuchFilesystemError - No such filesystem exists '#{command}'.")
          SZMGMT.logger.error("----> (stderr) #{stderr}")
          super(stderr)
        end
      end
    end
  end
end