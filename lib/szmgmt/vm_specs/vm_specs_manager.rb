module SZMGMT
  module VMSpecs
    class VMSpecsManager
      def self.validate_vm_spec(path_to_spec, full_validation = false, vm_spec = nil)
        vm_spec ||= JSONLoader.load_json(path_to_spec)
        if full_validation
          SZMGMT::JSONValidator.full_json_validation(VMSpecs.configuration[:basic_schema_path], vm_spec)
        else
          SZMGMT::JSONValidator.json_validation(VMSpecs.configuration[:basic_schema_path], vm_spec)
        end
        # VMSpec is valid so we can load and pass it to validator of spec's type
        module_name = vm_spec['type'].upcase
        begin
          mod = SZMGMT.const_get("#{module_name}")
          advanecd_manager = mod.request_handler
          advanecd_manager.send("validate_#{module_name.downcase}_vm_spec", path_to_spec, full_validation, vm_spec)
        rescue NoMethodError
          raise Exceptions::ModuleInvalidInterfaceError.new(module_name, 'validate_vm_spec')
        end
        true
      end

      def self.load_vm_spec(path_to_spec)
        vm_spec = JSONLoader.load_json(path_to_spec)
        validate_vm_spec(path_to_spec, false, vm_spec)
        vm_spec
      end
    end
  end
end