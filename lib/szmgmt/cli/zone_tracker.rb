module SZMGMT
  module CLI
    class ZoneTracker
      DEFAULT_INDEX = {}
      # Create file structure if it does not
      # exists
      def initialize
        @journal_directory = File.join(CLI.configuration[:root_dir],  CLI.configuration[:journal_dir])
        @tracked_zones_file = File.join(@journal_directory, CLI.configuration[:tracked_zones])
        # Create directory with tracked zone file and create default
        # tracked_zone.json if it does not exists
        Dir.mkdir(@journal_directory) unless File.exists?(@journal_directory)
        File.open(@tracked_zones_file, 'w') {|f| f.write(DEFAULT_INDEX.to_json)} unless File.exists?(@tracked_zones_file)
        # Load tracked_zones
        @tracked_zones = load_tracked_zones
      end

      def track_zone(zone_identifier)
        zone_name, hostname = zone_identifier.split(':')
        zone_identifier = "#{zone_name}:localhost" unless hostname
        # Nevermind if zones is already tracked
        # rewrite the tracked zone with current info
        @tracked_zones[zone_identifier] = load_zone_info zone_identifier
        write_tracked_zones
      end

      def untrack_zone(zone_identifier)
        zone_name, hostname = zone_identifier.split(':')
        zone_identifier = "#{zone_name}:localhost" unless hostname
        # Remove key from tracked zones
        @tracked_zones.tap {|hs| hs.delete(zone_identifier)}
        write_tracked_zones
      end

      def change_status(zone_identifier, status)
        zone_name, hostname = zone_identifier.split(':')
        zone_identifier = "#{zone_name}:localhost" unless hostname
        if @tracked_zones[zone_identifier]
          @tracked_zones[zone_identifier]['zone_state'] = status
          write_tracked_zones
        else
          @tracked_zones[zone_identifier] = load_zone_info zone_identifier
          @tracked_zones[zone_identifier]['zone_state'] = status
          write_tracked_zones
        end
      end

      def clear
        @tracked_zones = DEFAULT_INDEX
        write_tracked_zones
      end

      def update_zone(zone_identifier)
        zone_name, hostname = zone_identifier.split(':')
        zone_identifier = "#{zone_name}:localhost" unless hostname
        @tracked_zones[zone_identifier] = load_zone_info zone_identifier
        write_tracked_zones
      end

      def update
        clear
        CLI.host_manager.load_all_hosts.each do |hostname|
          if hostname == 'localhost'
            zone_strings = SZMGMT::SZONES::SZONESBasicRoutines.list_zones
          else
            host_spec = CLI.host_manager.load_host_spec(hostname)
            zone_strings = SZMGMT::SZONES::SZONESBasicRoutines.list_zones(host_spec)
          end
          zone_strings.each_line do |zone_string|
            zone = Zone.new.initialize_from_string(zone_string, hostname)
            next if zone.zone_name =~ /global/
            @tracked_zones[zone.zone_name] = zone.to_h
          end
        end
        write_tracked_zones
      end

      def list
        @tracked_zones
      end

      def status
        fresh_zones = {}
        CLI.host_manager.load_all_hosts.each do |hostname|
          if hostname == 'localhost'
            zone_strings = SZMGMT::SZONES::SZONESBasicRoutines.list_zones
          else
            host_spec = CLI.host_manager.load_host_spec(hostname)
            zone_strings = SZMGMT::SZONES::SZONESBasicRoutines.list_zones(host_spec)
          end
          zone_strings.each_line do |zone_string|
            zone = Zone.new.initialize_from_string(zone_string, hostname)
            next if zone.zone_name =~ /global/
            fresh_zones[zone.zone_name] = zone.to_h
          end
        end
        [@tracked_zones, fresh_zones]
      end

      private

      def load_zone_info(zone_identifier)
        zone_name, hostname = zone_identifier.split(':')
        # The zone is from remote host
        if hostname != 'localhost'
          host_spec = CLI.host_manager.load_host_spec(hostname)
          host_spec = SZMGMT::Entities::HostSpec.new(hostname) unless host_spec
          zone_string = SZMGMT::SZONES::SZONESBasicRoutines.list_zone(zone_name, host_spec)
        else
          zone_string = SZMGMT::SZONES::SZONESBasicRoutines.list_zone(zone_name)
        end
        Zone.new.initialize_from_string(zone_string, hostname).to_h
      end

      def load_tracked_zones
        begin
          json_raw = File.read(@tracked_zones_file)
          JSON.parse(json_raw)
        rescue Errno::ENOENT
          DEFAULT_INDEX
        rescue JSON::ParserError
          DEFAULT_INDEX
        end
      end

      def write_tracked_zones
        begin
          File.open(@tracked_zones_file,'w') do |file|
            file.write(JSON.pretty_generate(@tracked_zones))
          end
        rescue Errno::ENOENT
          false
        end
        true
      end
    end
  end
end