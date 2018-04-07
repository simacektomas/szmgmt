module SZMGMT
  module Templates
    class JSONLoader
      def self.load_template_hash(template_path)
        begin
          template_raw = File.read(template_path)
          JSON.parse(template_raw)
        rescue Errno::ENOENT
          raise SZMGMT::Exceptions::InvalidPathError.new(template_path)
        rescue JSON::ParserError
          raise SZMGMT::Exceptions::TemplateParseError.new(template_path)
        end
      end

      def self.load_template(template_path)
        template_data = load_template_hash(template_data)
        Entities::Template.new(template_data, template_path)
      end

      def self.load_schema_hash(schema_path)
        begin
          schema_raw = File.read(schema_path)
          JSON.parse(schema_raw)
        rescue Errno::ENOENT
          raise SZMGMT::Exceptions::InvalidPathError.new(schema_path)
        rescue JSON::ParserError
          raise SZMGMT::Exceptions::TemplateParseError.new(schema_path)
        end
      end

      def self.load_schema(schema_path)
        schema_data = load_schema_hash(schema_path)
        Entities::Schema.new(schema_data, schema_path)
      end
    end
  end
end
