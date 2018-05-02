module SZMGMT
  module SZONES
    class SZONESRecoveryRoutines
      def self.recover_local_zone_zfs_archives(zone_name, backup_path, opts = {})
        logger            = opts[:logger] || SZMGMT.logger
        boot              = opts[:boot] || false
        force             = opts[:force] || false
        cleaner           = SZONESCleanuper.new
        id                = SZONESUtils.transaction_id
        subroutine_option = {
            :logger => logger,
            :cleaner => cleaner,
            :id => id
        }
        logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} on localhost has been initialize...")
        begin
          SZONESBasicRoutines.remove_zone(zone_name) if force
          SZONESDeploymentSubroutines.deploy_zone_from_zfs_backup(zone_name, backup_path, subroutine_option)
        rescue Exceptions::SZONESError
          logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} failed.")
          cleaner.cleanup_on_failure!
          false
        else
          logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} succeeded.")
          if boot
            logger.info("RECOVERY (#{id}) - Booting up zone #{zone_name}")
            SZONESBasicZoneCommands.boot_zone(zone_name).exec
            logger.info("RECOVERY (#{id}) - Zone #{zone_name} booted.")
          end
          true
        ensure
          cleaner.cleanup_temporary!
        end
      end

      def self.recover_remote_zone_zfs_archives(zone_name, dest_host_spec, backup_path, opts = {})
        logger            = opts[:logger] || SZMGMT.logger
        boot              = opts[:boot] || false
        force             = opts[:force] || false
        tmp_dir           = opts[:tmp_dir] || '/var/tmp'
        cleaner           = SZONESCleanuper.new
        id                = SZONESUtils.transaction_id
        subroutine_option = {
            :logger => logger,
            :cleaner => cleaner,
            :id => id
        }
        logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} on #{dest_host_spec[:hostname]} has been initialize...")
        begin
          SZONESBasicCommands.copy_files_on_remote_host(backup_path, dest_host_spec, tmp_dir).exec
          remote_path = File.join(tmp_dir, backup_path.split('/').last)
          cleaner.add_tmp_file(remote_path, dest_host_spec)
          Net::SSH.start(dest_host_spec[:host_name], dest_host_spec[:user], dest_host_spec.to_h) do |ssh|
            SZONESBasicRoutines.remove_zone(zone_name, ssh) if force
            SZONESDeploymentSubroutines.deploy_zone_from_zfs_backup(zone_name, remote_path, subroutine_option, ssh, dest_host_spec)
          end
        rescue Exceptions::SZONESError
          logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} failed.")
          cleaner.cleanup_on_failure!
          false
        else
          logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} succeeded.")
          if boot
            logger.info("RECOVERY (#{id}) - Booting up zone #{zone_name}")
            SZONESBasicZoneCommands.boot_zone(zone_name).exec
            logger.info("RECOVERY (#{id}) - Zone #{zone_name} booted.")
          end
          true
        ensure
          cleaner.cleanup_temporary!
        end
      end

      def self.recover_local_zone_uar(zone_name, backup_path, opts = {})
        logger            = opts[:logger] || SZMGMT.logger
        boot              = opts[:boot] || false
        force             = opts[:force] || false
        cleaner           = SZONESCleanuper.new
        id                = SZONESUtils.transaction_id
        subroutine_option = {
            :logger => logger,
            :cleaner => cleaner,
            :id => id
        }
        logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} on localhost has been initialize...")
        begin
          SZONESBasicRoutines.remove_zone(zone_name) if force
          SZONESDeploymentSubroutines.deploy_zone_from_uar(zone_name, backup_path, subroutine_option)
        rescue Exceptions::SZONESError
          logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} failed.")
          cleaner.cleanup_on_failure!
          false
        else
          logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} succeeded.")
          if boot
            logger.info("RECOVERY (#{id}) - Booting up zone #{zone_name}")
            SZONESBasicZoneCommands.boot_zone(zone_name).exec
            logger.info("RECOVERY (#{id}) - Zone #{zone_name} booted.")
          end
          true
        ensure
          cleaner.cleanup_temporary!
        end
      end

      def self.recover_remote_zone_uar(zone_name, dest_host_spec, backup_path, opts = {})
        logger            = opts[:logger] || SZMGMT.logger
        boot              = opts[:boot] || false
        force             = opts[:force] || false
        tmp_dir           = opts[:tmp_dir] || '/var/tmp'
        cleaner           = SZONESCleanuper.new
        id                = SZONESUtils.transaction_id
        subroutine_option = {
            :logger => logger,
            :cleaner => cleaner,
            :id => id
        }
        logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} on #{dest_host_spec[:hostname]} has been initialize...")
        begin
          SZONESBasicCommands.copy_files_on_remote_host(backup_path, dest_host_spec, tmp_dir).exec
          remote_path = File.join(tmp_dir, backup_path.split('/').last)
          cleaner.add_tmp_file(remote_path, dest_host_spec)
          Net::SSH.start(dest_host_spec[:host_name], dest_host_spec[:user], dest_host_spec.to_h) do |ssh|
            SZONESBasicRoutines.remove_zone(zone_name, ssh) if force
            SZONESDeploymentSubroutines.deploy_zone_from_uar(zone_name, remote_path, subroutine_option, ssh, dest_host_spec)
          end
        rescue Exceptions::SZONESError
          logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} failed.")
          cleaner.cleanup_on_failure!
          false
        else
          logger.info("RECOVERY (#{id}) - Recovery of zone #{zone_name} succeeded.")
          if boot
            logger.info("RECOVERY (#{id}) - Booting up zone #{zone_name}")
            SZONESBasicZoneCommands.boot_zone(zone_name).exec
            logger.info("RECOVERY (#{id}) - Zone #{zone_name} booted.")
          end
          true
        ensure
          cleaner.cleanup_temporary!
        end
      end
    end
  end
end