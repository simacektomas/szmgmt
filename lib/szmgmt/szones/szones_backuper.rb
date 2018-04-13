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

      def backup_using_uar(backup_dir = "/var/tmp")
        # For each hostname that we have to backup some zones run individual thread
        SZMGMT.logger.info("BACKUP: Unified arhive backup initialized")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |key|
          SZMGMT.logger.info("BACKUP: Backup of zones #{@zones_by_hosts[key]} on host #{key} has been initialized.")
          uar_routine(@host_specs[key], @zones_by_hosts[key], backup_dir)
        end
      end

      def backup_using_zfs_archives(backup_dir = "/var/tmp")
        # For each hostname that we have to backup some zones run individual thread
        SZMGMT.logger.info("BACKUP: ZFS archives backup initialized")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |key|
          SZMGMT.logger.info("BACKUP: Backup of zones #{@zones_by_hosts[key]} on host #{key} has been initialized.")
          zfs_archives_routine(@host_specs[key], @zones_by_hosts[key], backup_dir)
        end
      end

      private

      def zfs_archives_routine(host_spec, zone_names, backup_dir)
        if host_spec[:host_name] == 'localhost'
          Parallel.each(zone_names) do |zone_name|
            file_name = File.join(backup_dir, "#{zone_name}_#{Time.now.to_i}.zfs.gz")
            SZMGMT.logger.info("BACKUP: (#{host_spec[:host_name]})  Backuping of zone #{zone_name} to #{file_name} initialized...")
            SZONESRoutines.backup_zone_zfs_archive(zone_name, file_name)
            SZMGMT.logger.info("BACKUP: (#{host_spec[:host_name]})  Backuping of zone #{zone_name} finished.")
          end
        else
          Parallel.each(zone_names) do |zone_name|
            file_name = File.join(backup_dir, "#{zone_name}_#{Time.now.to_i}.zfs.gz")
            Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
              SZMGMT.logger.info("BACKUP: (#{host_spec[:host_name]}) Backuping of zone #{zone_name} to #{file_name} initialized...")
              SZONESRoutines.backup_zone_zfs_archive(zone_name, file_name, ssh)
              SZMGMT.logger.info("BACKUP: (#{host_spec[:host_name]})  Backuping of zone #{zone_name} finished.")
            end
          end
        end
      end

      def uar_routine(host_spec, zone_names, backup_dir)

        if host_spec[:host_name] == 'localhost'
          zone_names.each do |zone_name|
            file_name = File.join(backup_dir, "#{zone_name}_#{Time.now.to_i}.uar")
            SZMGMT.logger.info("BACKUP: (#{host_spec[:host_name]})  Backuping of zone #{zone_name} to #{file_name} initialized...")
            SZONESRoutines.backup_zone_uar(zone_name, file_name)
            SZMGMT.logger.info("BACKUP: (#{host_spec[:host_name]})  Backuping of zone #{zone_name} finished.")
          end
        else
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
            zone_names.each do |zone_name|
              file_name = File.join(backup_dir, "#{zone_name}_#{Time.now.to_i}.uar")
              SZMGMT.logger.info("BACKUP: (#{host_spec[:host_name]})  Backuping of zone #{zone_name} to #{file_name} initialized...")
              SZONESRoutines.backup_zone_uar(zone_name, file_name, ssh)
              SZMGMT.logger.info("BACKUP: (#{host_spec[:host_name]})  Backuping of zone #{zone_name} finished.")
            end
          end
        end
      end
    end
  end
end