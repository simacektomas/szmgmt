module SZMGMT
  module SZONES
    module Exceptions
      class ZonecfgNoSuchZoneError < SZONESError
        def initialize(command, stderr)
          SZMGMT.logger.error("ZonecfgNoSuchZoneError - No such zone exists '#{command}'.")
          SZMGMT.logger.error("----> (stderr) #{stderr}")
          super(stderr)
        end
      end
    end
  end
end