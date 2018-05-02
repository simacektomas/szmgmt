module SZMGMT
  module CLI
    class ZoneRecoverer
      def initialize
        @zones_by_hosts = Hash.new { |h, k| h[k] = [] }
        @host_specs = {}
      end

      def add_zone(zone_name, archive_path, host_spec = {:host_name => 'localhost'})
        @zones_by_hosts[host_spec[:host_name]] << [zone_name, archive_path]
        @host_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def recover_zones(options = {})
        force = options[:force] || false
        boot  = options[:boot] || false
        routine_options = {
            :force => force,
            :boot => boot
        }
        log_dir = File.join(CLI.configuration[:root_dir], CLI.configuration[:log_dir])
        puts "Solaris zones recovery initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "                Boot zones: #{boot ? "enable" : "disable"}"
        puts "    Rewrite existing zones: #{force ? "enable" : "disable"}"
        puts "  ---------------------------------------------------------"
        puts "  Connecting concurrently to hosts '#{@host_specs.keys.join(', ')}' to recovery."
        result_all = Parallel.map(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          Parallel.map(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |couple|
            zone_name = couple.first
            archive_path = couple.last
            log_name = "#{zone_name}_recovery_#{rand(36**6).to_s(36)}.log"
            routine_options[:logger] = Logger.new(File.join(log_dir, log_name))
            puts "  Processing zone '#{zone_name}' recovery on host '#{host_name}'."
            puts "    Source archive: #{archive_path}."
            puts "    See log '#{File.join(log_dir, log_name)}'."
            if host_name == 'localhost'
              if archive_path.split('.').last == 'zip'
                SZMGMT::SZONES::SZONESRecoveryRoutines.recover_local_zone_zfs_archives(zone_name, archive_path, routine_options)
              elsif archive_path.split('.').last == 'uar'
                SZMGMT::SZONES::SZONESRecoveryRoutines.recover_local_zone_uar(zone_name, archive_path, routine_options)
              else
                puts "    Error: Invalid archive type #{archive_path}."
              end
            else
              if archive_path.split('.').last == 'zip'
                SZMGMT::SZONES::SZONESRecoveryRoutines.recover_remote_zone_zfs_archives(zone_name, @host_specs[host_name], archive_path, routine_options)
              elsif archive_path.split('.').last == 'uar'
                SZMGMT::SZONES::SZONESRecoveryRoutines.recover_remote_zone_uar(zone_name, @host_specs[host_name], archive_path, routine_options)
              else
                puts "    Error: Invalid archive type #{archive_path}."
              end
            end
          end
        end
        puts "  ---------------------------------------------------------"
        puts "  Recovery finished."
        puts "    Status:"
        @zones_by_hosts.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          @zones_by_hosts[host_name].each_with_index do |couple, zone_index|
            puts "        #{couple.first}: #{result_all[host_index][zone_index] ? 'success': 'failed'}"
            CLI.zone_tracker.track_zone "#{couple.first}:#{host_name}" if result_all[host_index][zone_index]
          end
        end
      end
    end
  end
end