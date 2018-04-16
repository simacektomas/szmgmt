module SZMGMT
  module SZONES
    class SZONESAPI
      def initialize
      end
      ########################################################
      # API COMMANDS
      ########################################################
      def validate_szones_vm_spec(path_to_spec, full_validation = false, vm_spec = nil)
        SZONESVMSpecManager.validate_vm_spec(path_to_spec, full_validation, vm_spec)
      end
    end
  end
end