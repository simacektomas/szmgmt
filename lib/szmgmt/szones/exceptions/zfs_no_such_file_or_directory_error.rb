module SZMGMT
  module SZONES
    module Exceptions
      class ZFSNoSuchFileOrDirectoryError < StandardError
        def initialize(stderr)
          super(stderr)
        end
      end
    end
  end
end