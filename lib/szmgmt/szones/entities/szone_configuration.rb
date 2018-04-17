module SZMGMT
  module SZONES
    module Entities
      class SZONEConfiguration
        def initialize(vm_spec_configuration)
          @vm_spec_configuration = vm_spec_configuration
          if @vm_spec_configuration
            @zonecfg_commands = ['create -b']
            parse_configuration
          else
            @zonecfg_commands = ['create']
            @zonecfg_commands << 'exit'
          end
        end

        def export_configuration
          @zonecfg_commands.join("\n")
        end

        def export_configuration_to_file(path_to_file)
          File.open(path_to_file, 'w') do |file|
            file.write(export_configuration)
          end
        end

        private
        # Parse configuration of VMSpec to export format
        # that can be imported to zonecfg command
        def parse_configuration
          @vm_spec_configuration.each do |property, value|
            if property == 'resources'
              parse_resources(value)
            else
              @zonecfg_commands << "set #{property}=#{value}"
            end
          end
          @zonecfg_commands << 'exit'
        end

        def parse_resources(resources)
          resources.each do |resource|
            resource_name = resource['type']
            resource_properties = resource['values']
            @zonecfg_commands << "add #{resource_name}"
            resource_properties.each do |property, value|
              @zonecfg_commands << "set #{property}=#{value}"
            end
            @zonecfg_commands << "end"
          end
        end
      end
    end
  end
end