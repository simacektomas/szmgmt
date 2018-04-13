module SZMGMT
  module SZONES
    class SZONESBackuper

      attr_reader :zone_by_hosts

      def initialize
        @zones_by_hosts = Hash.new { |h, k| h[k] = [] }
        @host_specs = {}
      end

      def add_zone_to_backup(zone_name, host_spec = {:host_name => 'localhost'})
        @zones_by_hosts[host_spec[:host_name]] << zone_name
        @host_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def backup_using_uar()
        # For each hostname that we have to backup some zones run individual thread
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |key|
          uar_routine(@host_specs[key], @zones_by_hosts[key])
        end
      end

      def backup_using_zfs_archives()
        # For each hostname that we have to backup some zones run individual thread
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |key|
          zfs_archives_routine(@host_specs[key], @zones_by_hosts[key])
        end
      end

      private

      def zfs_archives_routine(host_spec, zone_names)
        if host_spec[:host_name] == 'localhost'
          Parallel.each(zone_names) do |zone_name|
            SZONESRoutines.backup_zone_zfs_archive(zone_name, "/var/tmp/#{zone_name}_#{Time.now.to_i}.zfs.gz")
          end
        else
          Parallel.each(zone_names) do |zone_name|
            Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
              SZONESRoutines.backup_zone_zfs_archive(zone_name, "/var/tmp/#{zone_name}_#{Time.now.to_i}.zfs.gz", ssh)
            end
          end
        end
      end

      def uar_routine(host_spec, zone_names)
        if host_spec[:host_name] == 'localhost'
          zone_names.each do |zone_name|
            SZONESRoutines.backup_zone_uar(zone_name, "/var/tmp/#{zone_name}_#{Time.now.to_i}.uar")
          end
        else
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
            zone_names.each do |zone_name|
              SZONESRoutines.backup_zone_uar(zone_name, "/var/tmp/#{zone_name}_#{Time.now.to_i}.uar", ssh)
            end
          end
        end
      end

    end
  end
end