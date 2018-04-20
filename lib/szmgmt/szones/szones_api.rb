module SZMGMT
  module SZONES
    class SZONESAPI

      def request_handlers
        [
          SZONESBasicRoutines,
          SZONESDeploymentRoutines,
          SZONESMigrationRoutines,
          SZONESBackupRoutines,
          SZONESVMSpecManager
        ]
      end

      def method_missing(method, *args, &block)
        request_handlers.each do |request_handler|
          if request_handler.respond_to?(method)
            request_handler.send(method, *args, &block)
            return
          end
        end
        raise SZMGMT::Exceptions::APIMethodMissingError.new(method)
      end

      def respond_to_missing?(method_name, include_private = false)
        request_handlers.each do |request_handler|
          return true if request_handler.respond_to?(method_name, include_private)
        end
        false
      end
    end
  end
end