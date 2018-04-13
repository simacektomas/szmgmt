module SZMGMT
  module SZONES
    module Exceptions
      class BashNotaDirectoryError < StandardError
        def initialize(stderr)
          super(stderr)
        end
      end
    end
  end
end