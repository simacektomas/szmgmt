module SZMGMT
  class SZMGMTAPI
    def initialize
      SZMGMT.logger.info("Initializing SZMGMT modules.")
      init_modules
      SZMGMT.logger.info("Registering handlers for modules.")
      register_request_handlers
    end

    # Routing to request handlers of application modules

    def method_missing(method, *args, &block)
      SZMGMT.logger.debug("Request for calling API method \'#{method}\'.")
      @request_handlers.each do |request_handler|
        if request_handler.respond_to?(method)
          SZMGMT.logger.debug("Routing to request handler \'#{request_handler.to_s}\'.")
          request_handler.send(method, *args, &block)
          return
        end
      end
      raise Exceptions::APIMethodMissingError.new(method)
    end

    def respond_to_missing?(method_name, include_private = false)
      @request_handlers.each do |request_handler|
        return true if request_handler.respond_to?(method_name, include_private)
      end
      false
    end

    def validate_vm_spec(path_to_spec, full_validation = false)
      VMSpecs::VMSpecsManager.validate_vm_spec(path_to_spec, full_validation)
    end

    def load_vm_spec(path_to_spec)
      VMSpecs::VMSpecsManager.load_vm_spec(path_to_spec)
    end

    #############################################################################
    # API METHODS
    #############################################################################
    # Returns HostSpec class that specify how to connect to host with ssh
    def create_host_spec(hostname, options = {})
      Entities::HostSpec.new(hostname, options)
    end

    private

    def init_modules
      # initialize all modules of applicataion (call init method)
      modules = SZMGMT.configuration[:vm_modules]
      modules.each do |module_name|
        SZMGMT.logger.info("Loading and initializing module \'#{module_name.upcase}\'.")
        begin
          modul = SZMGMT.const_get module_name.upcase
          modul.init SZMGMT.configuration
          (@loaded_modules ||= []) << modul
        rescue NoMethodError
          raise Exceptions::ModuleInvalidInterfaceError.new(module_name.upcase, 'init')
        rescue NameError
          raise Exceptions::ModuleNotFoundedError.new(module_name.upcase)
        end
      end
      # initialize VMSpec module
      SZMGMT.logger.info("Initializing module 'VMSpecs'.")
      VMSpecs.init SZMGMT.configuration
    end

    def register_request_handlers
      # register request handlers for vm modules
      @loaded_modules.each do |modul|
        begin
          SZMGMT.logger.info("Registering request handler for module  #{modul.to_s}.")
          SZMGMT.logger.debug("Registering  #{modul.request_handler.class.to_s} request handler for module  #{modul.to_s}.")
          (@request_handlers ||= []) << modul.request_handler
        rescue NoMethodError
          raise Exceptions::ModuleInvalidInterfaceError.new(modul.to_s, 'request_handler')
        end
      end
    end
  end
end