module SZMGMT
  module CLI
    class ZoneMigrator
      def initialize(dest_host_spec)
        @zones_by_hosts = Hash.new { |h, k| h[k] = [] }
        @host_specs = {}
        @dest_host_spec = dest_host_spec
      end

      def add_zone(zone_name, host_spec = {:host_name => 'localhost'})
        @zones_by_hosts[host_spec[:host_name]] << zone_name
        @host_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def migrate_directly(options = {})
        force = options[:force] || false
        boot  = options[:boot] || false
        routine_options = {
            :force => force,
            :boot => boot
        }
        log_dir = File.join(CLI.configuration[:root_dir], CLI.configuration[:log_dir])
        puts "Solaris zones migration initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "                Boot zones: #{boot ? "enable" : "disable"}"
        puts "    Rewrite existing zones: #{force ? "enable" : "disable"}"
        puts "  ---------------------------------------------------------"
        puts "  Connecting concurrently to hosts '#{@zones_by_hosts.keys.join(' ')}' to perform migration (direct)."
        result_all = Parallel.map(@zones_by_hosts.keys, in_threads: @zones_by_hosts.keys.size) do |host_name|
          Parallel.map(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            log_name = "#{zone}_migration_#{rand(36**6).to_s(36)}.log"
            routine_options[:logger] = Logger.new(File.join(log_dir, log_name))
            puts "  Processing migration of zone '#{zone}:#{host_name}' to host #{@dest_host_spec[:host_name]}. See log '#{File.join(log_dir, log_name)}'."
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_local_zone_directly(zone, @dest_host_spec, routine_options)
            else
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_remote_zone_directly(zone, @host_specs[host_name], @dest_host_spec, routine_options)
            end
          end
        end
        puts "  ---------------------------------------------------------"
        puts "  Migration finished."
        puts "    Status:"
        @zones_by_hosts.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          @zones_by_hosts[host_name].each_with_index do |zone_name, zone_index|
            puts "        #{zone_name}: #{result_all[host_index][zone_index] ? 'success': 'failed'}"
            CLI.zone_tracker.untrack_zone "#{zone_name}:#{host_name}" if result_all[host_index][zone_index]
            CLI.zone_tracker.track_zone "#{zone_name}:#{@dest_host_spec[:host_name]}" if result_all[host_index][zone_index]
          end
        end
      end

      def migrate_zfs(options = {})
        force = options[:force] || false
        boot  = options[:boot] || false
        routine_options = {
            :force => force,
            :boot => boot
        }
        log_dir = File.join(CLI.configuration[:root_dir], CLI.configuration[:log_dir])
        puts "Solaris zones migration initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "                Boot zones: #{boot ? "enable" : "disable"}"
        puts "    Rewrite existing zones: #{force ? "enable" : "disable"}"
        puts "  ---------------------------------------------------------"
        puts "  Connecting concurrently to hosts '#{@zones_by_hosts.keys.join(' ')}' to perform migration (ZFS)."
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_local_zone_zfs_archives(zone, @dest_host_spec)
            else
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_remote_zone_zfs_archives(zone, @host_specs[host_name], @dest_host_spec)
            end
          end
        end
      end

      def migrate_uar
        force = options[:force] || false
        boot  = options[:boot] || false
        routine_options = {
            :force => force,
            :boot => boot
        }
        log_dir = File.join(CLI.configuration[:root_dir], CLI.configuration[:log_dir])
        puts "Solaris zones migration initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "                Boot zones: #{boot ? "enable" : "disable"}"
        puts "    Rewrite existing zones: #{force ? "enable" : "disable"}"
        puts "  ---------------------------------------------------------"
        puts "  Connecting concurrently to hosts '#{@zones_by_hosts.keys.join(' ')}' to perform migration (UAR)."
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_local_zone_uar(zone, @dest_host_spec)
            else
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_remote_zone_uar(zone, @host_specs[host_name], @dest_host_spec)
            end
          end
        end
      end
    end
  end
end