module SZMGMT
  module CLI
    class ZoneBackuper

      attr_reader :zone_by_hosts
      attr_accessor :archive_destination

      def initialize
        @zones_by_hosts = Hash.new { |h, k| h[k] = [] }
        @host_specs = {}
      end

      def add_zone_to_backup(zone_name, host_spec = {:host_name => 'localhost'})
        @zones_by_hosts[host_spec[:host_name]] << zone_name
        @host_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def backup_using_uar(backup_dir = "/var/tmp", archive_destination = nil)
        routine_options = {
            :archive_destination => archive_destination
        }
        log_dir = File.join(CLI.configuration[:root_dir], CLI.configuration[:log_dir])
        puts "Solaris zones backup initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "          Backup directory: #{backup_dir}"
        puts "          Destination host: #{archive_destination[:host_name]}" if archive_destination
        puts "  ---------------------------------------------------------"
        puts "  Connecting concurrently to hosts '#{@host_specs.keys.join(', ')}' to perform backup (UAR)."
        result_all = Parallel.map(@zones_by_hosts.keys, in_threads: @zones_by_hosts.keys.size) do |host_name|
          local_result = []
          @zones_by_hosts[host_name].each do |zone_name|
            log_name = "#{zone_name}_backup_#{rand(36**6).to_s(36)}.log"
            routine_options[:logger] = Logger.new(File.join(log_dir, log_name))
            puts "  Processing zone backup of '#{zone_name}:#{host_name}'. See log '#{File.join(log_dir, log_name)}'."
            if host_name == 'localhost'
              local_result << SZMGMT::SZONES::SZONESBackupRoutines.backup_local_zone_uar(zone_name, backup_dir, routine_options)
            else
              local_result << SZMGMT::SZONES::SZONESBackupRoutines.backup_remote_zone_uar(zone_name,@host_specs[host_name], backup_dir, routine_options)
            end
          end
          local_result
        end
        puts "  ---------------------------------------------------------"
        puts "  Backup finished."
        puts "    Status:"
        @zones_by_hosts.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          @zones_by_hosts[host_name].each_with_index do |zone_name, zone_index|
            puts "        #{zone_name}: #{result_all[host_index][zone_index] ? 'success': 'failed'}"
          end
        end
      end

      def backup_using_zfs_archives(backup_dir = "/var/tmp", archive_destination = nil )
        routine_options = {
            :archive_destination => archive_destination
        }
        log_dir = File.join(CLI.configuration[:root_dir], CLI.configuration[:log_dir])
        puts "Solaris zones backup initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "          Backup directory: #{backup_dir}"
        puts "          Destination host: #{archive_destination[:host_name]}" if archive_destination
        puts "  ---------------------------------------------------------"
        puts "  Connecting concurrently to hosts '#{@host_specs.keys.join(', ')}' to perform backup (ZFS)."
        result_all = Parallel.map(@zones_by_hosts.keys, in_threads: @zones_by_hosts.keys.size) do |host_name|
          Parallel.map(@zones_by_hosts[host_name], in_threads: @zones_by_hosts[host_name].size) do |zone_name|
            log_name = "#{zone_name}_backup_#{rand(36**6).to_s(36)}.log"
            routine_options[:logger] = Logger.new(File.join(log_dir, log_name))
            puts "  Processing zone backup of '#{zone_name}:#{host_name}'. See log '#{File.join(log_dir, log_name)}'."
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESBackupRoutines.backup_local_zone_zfs_archives(zone_name, backup_dir, routine_options)
            else
              SZMGMT::SZONES::SZONESBackupRoutines.backup_remote_zone_zfs_archives(zone_name, @host_specs[host_name], backup_dir, routine_options)
            end
          end
        end
        puts "  ---------------------------------------------------------"
        puts "  Backup finished."
        puts "    Status:"
        @zones_by_hosts.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          @zones_by_hosts[host_name].each_with_index do |zone_name, zone_index|
            puts "        #{zone_name}: #{result_all[host_index][zone_index] ? 'success': 'failed'}"
          end
        end
      end
    end
  end
end