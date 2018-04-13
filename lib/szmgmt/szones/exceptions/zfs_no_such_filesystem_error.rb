module SZMGMT
  module SZONES
    module Exceptions
      class ZFSNoSuchFilesystemError < StandardError
        def initialize(stderr)
          super(stderr)
        end
      end
    end
  end
end