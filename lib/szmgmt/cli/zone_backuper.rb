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
        # For each hostname that we have to backup some zones run individual thread
        SZMGMT.logger.info("BACKUP: Unified arhive backup initialized")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |key|
          SZMGMT.logger.info("BACKUP:     Backup of zones #{@zones_by_hosts[key]} on host #{key} has been initialized.")
          uar_routine(@host_specs[key], @zones_by_hosts[key], backup_dir, archive_destination)
          SZMGMT.logger.info("BACKUP:     Backup of zones #{@zones_by_hosts[key]} on host #{key} finished.")
        end
        SZMGMT.logger.info("BACKUP: Unified arhive backup finished")
      end

      def backup_using_zfs_archives(backup_dir = "/var/tmp", archive_destination = nil )
        # For each hostname that we have to backup some zones run individual thread
        SZMGMT.logger.info("BACKUP: ZFS archives backup initialized")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |key|
          SZMGMT.logger.info("BACKUP:     Backup of zones #{@zones_by_hosts[key]} on host #{key} has been initialized.")
          zfs_archives_routine(@host_specs[key], @zones_by_hosts[key], backup_dir, archive_destination)
          SZMGMT.logger.info("BACKUP:     Backup of zones #{@zones_by_hosts[key]} on host #{key} finished.")
        end
        SZMGMT.logger.info("BACKUP: ZFS archives backup finished")
      end

      private

      def zfs_archives_routine(host_spec, zone_names, backup_dir, archive_destination)
        p host_spec
        p zone_names
        p backup_dir
        p archive_destination
        if host_spec[:host_name] == 'localhost'
          Parallel.each(zone_names) do |zone_name|
            SZMGMT.logger.info("BACKUP:         Backuping of zone #{host_spec[:host_name]}:#{zone_name} to #{backup_dir} #{"on #{archive_destination[:host_name]}" if archive_destination} initialized...")
            SZMGMT::SZONES::SZONESBackupRoutines.backup_local_zone_zfs_archives(zone_name, backup_dir, {:archive_destination => archive_destination})
            SZMGMT.logger.info("BACKUP:         Backuping of zone #{host_spec[:host_name]}:#{zone_name} finished.")
          end
        else
          Parallel.each(zone_names) do |zone_name|
            SZMGMT.logger.info("BACKUP:         Backuping of zone #{host_spec[:host_name]}:#{zone_name} to #{backup_dir} #{"on #{archive_destination[:host_name]}" if archive_destination} initialized...")
            SZMGMT::SZONES::SZONESBackupRoutines.backup_remote_zone_zfs_archives(zone_name, host_spec, backup_dir, {:archive_destination => archive_destination})
            SZMGMT.logger.info("BACKUP:         Backuping of zone #{host_spec[:host_name]}:#{zone_name} finished.")
          end
        end
      end

      def uar_routine(host_spec, zone_names, backup_dir, archive_destination)
        if host_spec[:host_name] == 'localhost'
          zone_names.each do |zone_name|
            SZMGMT.logger.info("BACKUP:         Backuping of zone #{host_spec[:host_name]}:#{zone_name} to #{backup_dir} #{"on #{archive_destination[:host_name]}" if archive_destination} initialized...")
            SZMGMT::SZONES::SZONESBackupRoutines.backup_local_zone_uar(zone_name, backup_dir, {:archive_destination => archive_destination})
            SZMGMT.logger.info("BACKUP:         Backuping of zone #{host_spec[:host_name]}:#{zone_name} finished.")
          end
        else
          zone_names.each do |zone_name|
            SZMGMT.logger.info("BACKUP:         Backuping of zone #{host_spec[:host_name]}:#{zone_name} to #{backup_dir} #{"on #{archive_destination[:host_name]}" if archive_destination} initialized...")
            SZMGMT::SZONES::SZONESBackupRoutines.backup_remote_zone_uar(zone_name,host_spec, backup_dir, {:archive_destination => archive_destination})
            SZMGMT.logger.info("BACKUP:         Backuping of zone #{host_spec[:host_name]}:#{zone_name} finished.")
          end
        end
      end
    end
  end
end