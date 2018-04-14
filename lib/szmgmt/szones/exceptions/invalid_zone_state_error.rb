module SZMGMT
  module SZONES
    module Exceptions
      class InvalidZoneStateError < SZONESError
        def initialize(command, stderr)
          SZMGMT.logger.error("InvalidZoneState - Zone is in invalid state for this kind of operation '#{command}'.")
          SZMGMT.logger.error("----> (stderr) #{stderr}")
          super(stderr)
        end
      end
    end
  end
end