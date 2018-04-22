module SZMGMT
  module CLI
    module Commands
      class Journal < Thor
        def initialize(*args)
          super(*args)
        end

        def self.command_name
          name.split('::').last.downcase
        end

        def self.usage
          "#{command_name} [SUBCOMMAND]"
        end

        def self.description
          "Journal command can be used to keep information about zones."
        end

        desc 'track [IDENTIFICATOR,]', 'Track command is used for registering zones into application.'

        def track(*zone_identifiers)
          zone_identifiers.each do |zone_id|
            begin
              STDOUT.puts "Adding zone #{zone_id} to tracked zones."
              CLI.zone_tracker.track_zone zone_id
            rescue SZMGMT::SZONES::Exceptions::NoSuchZoneError
              STDERR.puts "Cannot track zone #{zone_id}. Zone #{zone_id} does not exist."
            end
          end
        end

        desc 'untruck [IDENTIFICATOR,..]', 'Untrack command is used for remove zones into application.'

        def untrack(*zone_identifiers)
          zone_identifiers.each do |zone_id|
            STDOUT.puts "Removing zone #{zone_id} from tracked zones."
            CLI.zone_tracker.untrack_zone zone_id
          end
        end

        desc 'update [IDENTIFICATOR,..]', 'Update command will fetch info about zones on all registered hosts.'

        def update(*zone_identifiers)
          if zone_identifiers.empty?
            CLI.zone_tracker.update
          else
            zone_identifiers.each do |zone_identifier|
              CLI.zone_tracker.update_zone(zone_identifier)
            end
          end
        end

        desc 'list', 'List command will list stored information about tracked zones.'

        def list
          tracked_zones = CLI.zone_tracker.list
          tracked_zones_by_host = Hash.new { |h, k| h[k] = [] }
          tracked_zones.keys.each do |zone_identifier|
            zone_name, hostname = zone_identifier.split(':')
            tracked_zones_by_host[hostname] << tracked_zones[zone_identifier]
          end

          STDOUT.puts 'Tracked zones:' unless tracked_zones_by_host.keys.empty?
          tracked_zones_by_host.keys.each do |hostname|
            STDOUT.puts "  Host #{hostname}"
            tracked_zones_by_host[hostname].each do |zone_hash|
              print_untracked zone_hash
            end
          end
        end

        desc 'status', 'Status command will check zones all over registered hosts and compare it to tracked zones.'

        def status
          STDOUT.puts 'Geting fresh information about zones on all registered hosts...'
          tracked_zones, fresh_zones = CLI.zone_tracker.status
          tracked_zones_by_host = Hash.new { |h, k| h[k] = [] }
          untracked_zones_by_host = Hash.new { |h, k| h[k] = [] }
          fresh_zones.keys.each do |zone_identifier|
            zone_name, hostname = zone_identifier.split(':')
            if tracked_zones[zone_identifier]
              # The zone is tracked compare with fresh zone
              tracked_zones_by_host[hostname] << tracked_zones[zone_identifier]
            else
              # Zone is untracked
              untracked_zones_by_host[hostname] << fresh_zones[zone_identifier]
            end
          end

          STDOUT.puts 'Tracked zones:' unless tracked_zones_by_host.keys.empty?
          tracked_zones_by_host.keys.each do |hostname|
            STDOUT.puts "  Host #{hostname}"
            tracked_zones_by_host[hostname].each do |zone_hash|
              print_comparison zone_hash, fresh_zones[zone_hash['zone_name']]
            end
          end

          STDOUT.puts 'Untracked zones:' unless untracked_zones_by_host.keys.empty?
          untracked_zones_by_host.keys.each do |hostname|
            STDOUT.puts "  Host #{hostname}"
            untracked_zones_by_host[hostname].each do |zone_hash|
              print_untracked zone_hash
            end
          end
        end

        desc 'clear', 'Clear command for removing all tracked zones from application.'

        def clear
          CLI.zone_tracker.clear
        end

        private

        def print_comparison(tracked, fresh)
          STDOUT.puts "      #{tracked['zone_name']}"
          STDOUT.puts "           Zone type: #{tracked['zone_brand']}"
          STDOUT.puts "                      MISMATCH - Fresh zone brand property is #{fresh['zone_brand']}. Use update to load the change." unless tracked['zone_brand'] == fresh['zone_brand']
          STDOUT.puts "          Zone state: #{tracked['zone_state']}"
          STDOUT.puts "                      MISMATCH - Fresh zone state property is #{fresh['zone_state']}. Use update to load the change." unless tracked['zone_state'] == fresh['zone_state']
          STDOUT.puts "           Zone path: #{tracked['zone_path']}"
          STDOUT.puts "                      MISMATCH - Fresh zone path property is #{fresh['zone_path']}. Use update to load the change." unless tracked['zone_path'] == fresh['zone_path']
          STDOUT.puts "                      MISMATCH - Fresh zone UUID mismatch. Disk image is different. Use update to load the change." unless tracked['zone_uuid'] == fresh['zone_uuid']

        end

        def print_untracked(untracked)
          STDOUT.puts "      #{untracked['zone_name']}"
          STDOUT.puts "          Zone type: #{untracked['zone_brand']}"
          STDOUT.puts "         Zone state: #{untracked['zone_state']}"
          STDOUT.puts "          Zone path: #{untracked['zone_path']}"
        end
      end
    end
  end
end
