module SZMGMT
  module SZONES
    module Exceptions
      class NoSuchZoneError < SZONESError
        def initialize(command, msg)
          SZMGMT.logger.error("NoSuchZoneError: (#{command}) No such zone exists.")
          super(msg)
        end
      end
    end
  end
end