module SZMGMT
  module SZONES
    @configuration = {
        :module_name => 'szones',
        :root_dataset => 'rpool/szones',
        :template_dataset => 'rpool/szones/templates',
        :default_dataset => 'rpool/szones/zones',
        :szones_schema => 'szone_template_schema.json',
        :szones_schema_path => '/etc/szmgmt/szones/szone_template_schema'
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

    # Demanded interface for VM_MODULE

    def self.init(global_configuration)
      # Determine schema path from global configuration
      # module name and name of the schema
      @configuration[:szones_schema_path] = File.join(SZMGMT.configuration[:root_dir],
                                                      @configuration[:module_name],
                                                      @configuration[:szones_schema])
      #init_datasets
    end

    def self.request_handler
      SZONES::SZONESAPI.new
    end

    private

    def self.init_datasets
      SZMGMT.logger.info "Initializing szones datasets."
      # Check for existence of service datasets [ root, templates, default ]
      ordered_datasetes = [ configuration[:root_dataset],
                            configuration[:template_dataset],
                            configuration[:default_dataset] ]
      zfs = ZFSDatasetManager
      ordered_datasetes.each do |dataset|
        unless zfs.dataset_exist?(dataset)
          unless zfs.create_dataset(dataset)
            SZMGMT.logger.error "Dataset #{dataset} cannot be created."
          else
            SZMGMT.logger.info "Dataset #{dataset} created."
          end
        end
      end
    end
  end
end