module SZMGMT
  module Templates
    @configuration = {
        :basic_schema => lambda { File.join(SZMGMT.configuration[:root_dir],  'basic_template_schema.json ') }
    }

    @valid_config_keys = @configuration.keys

    def self.configure(opts = {})
      opts.each do |key, value|
        @configuration[key.to_sym] = value if @valid_config_keys.include? key.to_sym
      end
    end

    def self.configure_with(path_to_json_file)
      configuration = JSONLoader.load_json(path_to_json_file)
      configure(configuration)
    end

    def self.configuration
      @configuration
    end

    def self.init(global_configuration = {})
      @configuration.each do |key, value|
        @configuration[key.to_sym] = value.call if value.is_a? Proc
      end
    end
  end
end