module SZMGMT
  module CLI
    class ZoneManager
      def initialize
        @zones_by_hosts = Hash.new { |h, k| h[k] = [] }
        @host_specs = {}
      end

      def add_zone(zone_name, host_spec = {:host_name => 'localhost'})
        @zones_by_hosts[host_spec[:host_name]] << zone_name
        @host_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def boot(*boot_opts)
        SZMGMT.logger.info("BOOT - Parallel boot of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated..")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("BOOT -    Parallel boot of zones '#{@zones_by_hosts[host_name].join(' ')}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            begin
              SZMGMT.logger.info("BOOT -        Booting zone #{zone}...")
              if host_name == 'localhost'
                SZMGMT::SZONES::SZONESBasicRoutines.boot_zone(zone, {:host_name => 'localhost'}, *boot_opts)
              else
                SZMGMT::SZONES::SZONESBasicRoutines.boot_zone(zone, @host_specs[host_name], *boot_opts)
              end
              SZMGMT.logger.warn("BOOT -        Booting of zone #{zone}:#{host_name} finished.")
            rescue SZMGMT::SZONES::Exceptions::SZONESError
              SZMGMT.logger.warn("BOOT - Zone #{zone}:#{host_name} is in invalid state for boot. (Already booted etc.")
            end
          end
        end
        SZMGMT.logger.info("BOOT - Parallel boot of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end

      def reboot(*boot_opts)
        SZMGMT.logger.info("REBOOT - Parallel reboot of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated..")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("REBOOT -    Parallel reboot of zones '#{@zones_by_hosts[host_name].join(' ')}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            begin
              SZMGMT.logger.info("REBOOT -        Rebooting zone #{zone}...")
              if host_name == 'localhost'
                SZMGMT::SZONES::SZONESBasicRoutines.reboot_zone(zone, {:host_name => 'localhost'}, *boot_opts)
              else
                SZMGMT::SZONES::SZONESBasicRoutines.reboot_zone(zone, @host_specs[host_name], *boot_opts)
              end
              SZMGMT.logger.warn("REBOOT -        Rebooting of zone #{zone}:#{host_name} finished.")
            rescue SZMGMT::SZONES::Exceptions::SZONESError
              SZMGMT.logger.warn("REBOOT - Zone #{zone}:#{host_name} is in invalid state for reboot.")
            end
          end
        end
        SZMGMT.logger.info("REBOOT - Parallel reboot of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end

      def halt
        SZMGMT.logger.info("HALT - Parallel halt of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated..")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("HALT -    Parallel halt of zones '#{@zones_by_hosts[host_name].join(' ')}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            begin
              SZMGMT.logger.info("HALT -        Halting zone #{zone}...")
              if host_name == 'localhost'
                SZMGMT::SZONES::SZONESBasicRoutines.halt_zone(zone)
              else
                SZMGMT::SZONES::SZONESBasicRoutines.halt_zone(zone, @host_specs[host_name])
              end
              SZMGMT.logger.warn("HALT -        Halting of zone #{zone}:#{host_name} finished.")
            rescue SZMGMT::SZONES::Exceptions::SZONESError
              SZMGMT.logger.warn("HALT - Zone #{zone}:#{host_name} is in invalid state for halt.")
            end
          end
        end
        SZMGMT.logger.info("HALT - Parallel halt of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end

      def shutdown
        SZMGMT.logger.info("SHUTDOWN - Parallel shutdown of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated..")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("SHUTDOWN -    Parallel shutdown of zones '#{@zones_by_hosts[host_name].join(' ')}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            begin
              SZMGMT.logger.info("SHUTDOWN -        Shutdowning zone #{zone}...")
              if host_name == 'localhost'
                SZMGMT::SZONES::SZONESBasicRoutines.shutdown_zone(zone)
              else
                SZMGMT::SZONES::SZONESBasicRoutines.shutdown_zone(zone, @host_specs[host_name])
              end
              SZMGMT.logger.warn("SHUTDOWN -        Shutdowning of zone #{zone}:#{host_name} finished.")
            rescue SZMGMT::SZONES::Exceptions::SZONESError
              SZMGMT.logger.warn("SHUTDOWN - Zone #{zone}:#{host_name} is in invalid state for shutdown.")
            end
          end
        end
        SZMGMT.logger.info("SHUTDOWN - Parallel uninstall of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end

      def uninstall
        SZMGMT.logger.info("UNINSTALL - Parallel uninstall of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated..")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("UNINSTALL -    Parallel uninstall of zones '#{@zones_by_hosts[host_name].join(' ')}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            begin
              SZMGMT.logger.info("UNINSTALL -        Uninstalling zone #{zone}...")
              if host_name == 'localhost'
                SZMGMT::SZONES::SZONESBasicRoutines.uninstall_zone(zone)
              else
                SZMGMT::SZONES::SZONESBasicRoutines.uninstall_zone(zone, @host_specs[host_name])
              end
              SZMGMT.logger.warn("UNINSTALL -        Uninstalling of zone #{zone}:#{host_name} finished.")
            rescue SZMGMT::SZONES::Exceptions::SZONESError
              SZMGMT.logger.warn("UNINSTALL - Zone #{zone}:#{host_name} is in invalid state for uninstall.")
            end
          end
        end
        SZMGMT.logger.info("UNINSTALL - Parallel uninstall of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end

      def unconfigure
        SZMGMT.logger.info("UNCONFIGURE - Parallel unconfiguration of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated..")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("UNCONFIGURE -    Parallel unconfiguration of zones '#{@zones_by_hosts[host_name].join(' ')}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            begin
              SZMGMT.logger.info("UNCONFIGURE -        Unconfiguration zone #{zone}...")
              if host_name == 'localhost'
                SZMGMT::SZONES::SZONESBasicRoutines.unconfigure_zone(zone)
              else
                SZMGMT::SZONES::SZONESBasicRoutines.unconfigure_zone(zone, @host_specs[host_name])
              end
              SZMGMT.logger.warn("UNCONFIGURE -        Unconfiguration of zone #{zone}:#{host_name} finished.")
            rescue SZMGMT::SZONES::Exceptions::SZONESError
              SZMGMT.logger.warn("UNCONFIGURE - Zone #{zone}:#{host_name} is in invalid state for unconfiguration.")
            end
          end
        end
        SZMGMT.logger.info("UNCONFIGURE - Parallel unconfiguration of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end
    end
  end
end