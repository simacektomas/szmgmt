module SZMGMT
  module CLI
    @configuration = {
        :root_dir => File.join(ENV['HOME'], '.szmgmt'),
        :index => 'hosts.json',
        :specs_dir => 'hosts',
        :tracked_zones => 'tracked_zones.json',
        :journal_dir => 'journal'
    }

    @valid_config_keys = @configuration.keys

    def self.configure(opts = {})
      opts.each do |key, value|
        @configuration[key.to_sym] = value if @valid_config_keys.include? key.to_sym
      end
    end

    def self.configuration
      @configuration
    end

    def self.api
      @api ||= SZMGMT::SZMGMTAPI.new
    end

    def self.host_manager
      @host_manager ||= SZMGMT::CLI::HostManager.new
    end

    def self.zone_tracker
      @zone_tracker ||= SZMGMT::CLI::ZoneTracker.new
    end
  end
end