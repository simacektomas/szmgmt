module SZMGMT
  module Templates
    class TemplateValidator
      def self.full_template_validation(schema, template)
        errors = JSON::Validator.fully_validate(schema.data, template.data)
        raise SZMGMT::Exceptions::TemplateInvalidError.new(template.path,
                                                           schema.path,
                                                           report) unless errors.empty?
      end

      def self.template_validation(schema, template)
        valid = JSON::Validator.validate(schema.data, template.data)
        raise SZMGMT::Exceptions::TemplateInvalidError.new(template.path,
                                                           schema.path) unless valid
      end
    end
  end
end
