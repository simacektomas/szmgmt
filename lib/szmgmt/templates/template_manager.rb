module SZMGMT
  module Templates
    class TemplateManager
      def initialize(configuration = SZMGMT::Configuration.new)
        @configuration = configuration
        @json_loader = JSONLoader
        @template_validator = TemplateValidator
      end

      def load_template(template_path)
        @json_loader.load_template(template_path)
      end

      def load_schema(schema_path)
        @json_loader.load_schema(schema_path)
      end

      def load_schema_by_type(type)
        path = File.join(@configuration.schema_dir, "#{type}_template_schema.json")
        load_schema(path)
      end

      def validate_template(template, full_validation = false)
        # Construct basic schema entity from configuration
        basic_schema = load_schema_by_type("basic")
        # Validate template over basic schema.
        schema_validation(template, basic_schema, full_validation)
        # We know the template has valid type => Further validation
        advanced_schema = load_schema_by_type(template.data['type'])
        schema_validation(template, advanced_schema, full_validation )
        true
      end

      private

      def schema_validation(template, schema, full_validation = false)
        if full_validation
          @template_validator.full_template_validation(schema, template)
        else
          @template_validator.template_validation(schema, template)
        end
      end
    end
  end
end
