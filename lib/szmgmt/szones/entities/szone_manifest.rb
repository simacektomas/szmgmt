module SZMGMT
  module SZONES
    module Entities
      class SZONEManifest
        def initialize(vm_spec_manifest)
          @vm_spec_manifest = vm_spec_manifest
          @solaris_packages = []
          @manifest_template = ''
          parse_manifest
          load_manifest_template
        end

        def export_manifest
          @manifest_template % {:packages => @solaris_packages.join("\n                ")}
        end

        def export_manifest_to_file(path_to_file)
          File.open(path_to_file, 'w') do |file|
            file.write(export_manifest)
          end
        end

        private

        def parse_manifest
          @vm_spec_manifest.each do |property, value|
            begin
              self.send("parse_#{property}", value)
            rescue NoMethodError
              SZMGMT.logger.warn("MANIFEST - Unrecognized property #{property}. Skipping...")
            end
          end
        end

        def parse_packages(packages)
          packages.each do |package|
            @solaris_packages << "<name>#{package}</name>"
          end
        end

        def load_manifest_template
          File.open(SZONES.configuration[:manifest_template_path], 'r') do |file|
            file.each_line do |line|
              @manifest_template << line
            end
          end
        end
      end
    end
  end
end