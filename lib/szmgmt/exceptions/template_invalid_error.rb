module SZMGMT
  module Exceptions
    class TemplateInvalidError < StandardError
      attr_reader :errors
      def initialize(schema, errors=[])
        @errors = errors
        super("Template does not follow the #{schema} schema. #{@errors}")
      end
    end
  end
end
