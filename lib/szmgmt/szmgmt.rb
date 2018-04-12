module SZMGMT
  # Default configuration values
  @configuration = {
      :app_name => 'szmgmt',
      :root_dir => '/etc/szmgmt/',
      :log_dir => '/var/log/szmgmt',
      :vm_modules => [ 'szones' ]
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

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
end
