module SZMGMT
  module SZONES
    class SZONESVMSpecParser
      def initialize(vm_spec)
        @vm_spec = vm_spec
      end

      def vm_spec_configuration
        if @vm_spec['configuration']
          @szone_configuration ||= Entities::SZONEConfiguration.new(@vm_spec['configuration'])
        end
      end

      def vm_spec_manifest
        if @vm_spec['manifest']
          @szone_manifest ||= Entities::SZONEManifest.new(@vm_spec['manifest'])
        end
      end

      def vm_spec_profile
        if @vm_spec['profile']
          @szone_profile ||= Entities::SZONEProfile.new(@vm_spec['profile'])
        end
      end
    end
  end
end