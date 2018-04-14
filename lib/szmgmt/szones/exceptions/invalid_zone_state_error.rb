module SZMGMT
  module SZONES
    module Exceptions
      class InvalidZoneStateError < SZONESError
        def initialize(command, msg)
          SZMGMT.logger.error("InvalidZoneState - (#{command}) Zone is in invalid state for this kind of operation.")
          super(msg)
        end
      end
    end
  end
end