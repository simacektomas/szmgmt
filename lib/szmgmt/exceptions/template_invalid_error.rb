module SZMGMT
  module Exceptions
    class TemplateInvalidError < StandardError
      attr_reader :errors
      def initialize(template, schema, errors=[])
        @errors = errors
        super("Template on path #{template} does not follow the #{schema} schema.")
      end
    end
  end
end
