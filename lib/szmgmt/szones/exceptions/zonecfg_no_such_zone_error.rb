module SZMGMT
  module SZONES
    module Exceptions
      class ZonecfgNoSuchZoneError < StandardError
        def initialize(stderr)
          super(stderr)
        end
      end
    end
  end
end