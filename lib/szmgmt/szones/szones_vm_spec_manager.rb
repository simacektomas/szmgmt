module SZMGMT
  module SZONES
    class SZONESVMSpecManager
      def self.validate_szones_vm_spec(path_to_spec, full_validation = false, vm_spec = nil)
        vm_spec ||= JSONLoader.load_json(path_to_spec)
        if full_validation
          SZMGMT::JSONValidator.full_json_validation(SZONES.configuration[:szones_schema_path], vm_spec)
        else
          SZMGMT::JSONValidator.json_validation(SZONES.configuration[:szones_schema_path], vm_spec)
        end
        vm_spec
      end
    end
  end
end