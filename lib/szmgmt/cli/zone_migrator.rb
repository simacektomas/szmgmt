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

      def migrate_directly
        SZMGMT.logger.info("MIGRATE - Parallel migration of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated. Using direct method...")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("MIGRATE -    Parallel migrations of zones '#{@zones_by_hosts[host_name].join(' ')}' on host '#{host_name}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            SZMGMT.logger.info("MIGRATE -        Migrating zone #{zone} from #{host_name} to #{@dest_host_spec[:host_name]}...")
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_local_zone_directly(zone, @dest_host_spec)
            else
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_remote_zone_directly(zone, @host_specs[host_name], @dest_host_spec)
            end
            SZMGMT.logger.warn("MIGRATE -        Migration of zone #{zone} from #{host_name} to #{@dest_host_spec[:host_name]} finished.")
          end
        end
        SZMGMT.logger.info("MIGRATE - Parallel migration of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end

      def migrate_zfs
        SZMGMT.logger.info("MIGRATE - Parallel migration of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated. Using ZFS archive method...")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("MIGRATE -    Parallel migrations of zones '#{@zones_by_hosts[host_name].join(' ')}' on host '#{host_name}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            SZMGMT.logger.info("MIGRATE -        Migrating zone #{zone} from #{host_name} to #{@dest_host_spec[:host_name]}...")
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_local_zone_zfs_archives(zone, @dest_host_spec)
            else
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_remote_zone_zfs_archives(zone, @host_specs[host_name], @dest_host_spec)
            end
            SZMGMT.logger.warn("MIGRATE -        Migration of zone #{zone} from #{host_name} to #{@dest_host_spec[:host_name]} finished.")
          end
        end
        SZMGMT.logger.info("MIGRATE - Parallel migration of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end

      def migrate_uar
        SZMGMT.logger.info("MIGRATE - Parallel migration of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' initiated. Using UAR method...")
        Parallel.each(@zones_by_hosts.keys, in_processes: @zones_by_hosts.keys.size) do |host_name|
          SZMGMT.logger.info("MIGRATE -    Parallel migrations of zones '#{@zones_by_hosts[host_name].join(' ')}' on host '#{host_name}' initiated..")
          Parallel.each(@zones_by_hosts[host_name], in_processes: @zones_by_hosts[host_name].size) do |zone|
            SZMGMT.logger.info("MIGRATE -        Migrating zone #{zone} from #{host_name} to #{@dest_host_spec[:host_name]}...")
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_local_zone_uar(zone, @dest_host_spec)
            else
              SZMGMT::SZONES::SZONESMigrationRoutines.migrate_remote_zone_uar(zone, @host_specs[host_name], @dest_host_spec)
            end
            SZMGMT.logger.warn("MIGRATE -        Migration of zone #{zone} from #{host_name} to #{@dest_host_spec[:host_name]} finished.")
          end
        end
        SZMGMT.logger.info("MIGRATE - Parallel migration of zones on hosts '#{@zones_by_hosts.keys.join(' ')}' finished.")
      end
    end
  end
end