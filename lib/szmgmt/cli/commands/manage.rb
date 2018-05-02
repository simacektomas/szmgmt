module SZMGMT
  module CLI
    module Commands
      class Manage < Thor
        def initialize(*args)
          super(*args)
          @manager = SZMGMT::CLI::ZoneManager.new
          @host_manager= SZMGMT::CLI::HostManager.new
        end

        def self.command_name
          name.split('::').last.downcase
        end

        def self.subcommand_names
          sub = []
          public_instance_methods(false).each do |m|
            sub << m.to_s
          end
          sub
        end

        def self.usage
          "#{command_name} SUBCOMMAND"
        end

        def self.description
          "Default desription of `#{command_name}` command. CHANGE IT!"
        end

        desc 'boot [ZONE_ID, ...]', 'Boot up zones specified on command line.'
        def boot(*zone_identifiers)
          zone_identifiers.each do |zoneid|
            zone_name, hostname = zoneid.split(':')
            host_spec = load_host_spec(hostname)
            if host_spec
              @manager.add_zone(zone_name, host_spec)
            else
              @manager.add_zone(zone_name)
            end
          end
          @manager.boot
        end

        desc 'halt [ZONE_ID, ...]', 'Run halt command for all specified zones.'
        def halt(*zone_identifiers)
          zone_identifiers.each do |zoneid|
            zone_name, hostname = zoneid.split(':')
            host_spec = load_host_spec(hostname)
            if host_spec
              @manager.add_zone(zone_name, host_spec)
            else
              @manager.add_zone(zone_name)
            end
          end
          @manager.halt
        end

        desc 'shutdown [ZONE_ID, ...]', 'Boot up zones specified on command line.'
        def shutdown(*zone_identifiers)
          zone_identifiers.each do |zoneid|
            zone_name, hostname = zoneid.split(':')
            host_spec = load_host_spec(hostname)
            if host_spec
              @manager.add_zone(zone_name, host_spec)
            else
              @manager.add_zone(zone_name)
            end
          end
          @manager.shutdown
        end

        desc 'reboot [ZONE_ID, ...]', 'Reboot zones specified on command line.'
        def reboot(*zone_identifiers)
          zone_identifiers.each do |zoneid|
            zone_name, hostname = zoneid.split(':')
            host_spec = load_host_spec(hostname)
            if host_spec
              @manager.add_zone(zone_name, host_spec)
            else
              @manager.add_zone(zone_name)
            end
          end
          @manager.reboot
        end

        desc 'uninstall [ZONE_ID, ...]', 'Uninstall zones specified on command line.'
        def uninstall(*zone_identifiers)
          zone_identifiers.each do |zoneid|
            zone_name, hostname = zoneid.split(':')
            host_spec = load_host_spec(hostname)
            if host_spec
              @manager.add_zone(zone_name, host_spec)
            else
              @manager.add_zone(zone_name)
            end
          end
          @manager.uninstall
        end

        desc 'unconfigure [ZONE_ID, ...]', 'Unconfigure up zones specified on command line.'
        def unconfigure(*zone_identifiers)
          zone_identifiers.each do |zoneid|
            zone_name, hostname = zoneid.split(':')
            host_spec = load_host_spec(hostname)
            if host_spec
              @manager.add_zone(zone_name, host_spec)
            else
              @manager.add_zone(zone_name)
            end
          end
          @manager.unconfigure
        end

        private

        def load_host_spec(hostname)
          if hostname
            host_spec = @host_manager.load_host_spec(hostname)
            # Create default spec for this host
            unless host_spec
              SZMGMT.logger.warn("Using default host_spec values for host #{hostname}")
              host_spec = SZMGMT::Entities::HostSpec.new(hostname).to_h
            end
          end
          host_spec
        end
      end
    end
  end
end