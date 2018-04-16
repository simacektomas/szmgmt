module SZMGMT
  class JSONValidator
    def self.full_json_validation(path_to_schema, path_to_json)
      errors = JSON::Validator.fully_validate(path_to_schema, path_to_json)
      raise SZMGMT::Exceptions::TemplateInvalidError.new(path_to_json,
                                                         path_to_schema,
                                                         errors) unless errors.empty?
    end

    def self.json_validation(path_to_schema, path_to_json)
      valid = JSON::Validator.validate(path_to_schema, path_to_json)
      raise SZMGMT::Exceptions::TemplateInvalidError.new(path_to_json,
                                                         path_to_schema) unless valid
    end
  end
end