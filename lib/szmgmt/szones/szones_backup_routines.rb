module SZMGMT
  module SZONES
    class SZONESBackupRoutines
      # Backup local zone using zfs archives method. It will
      # produce one archive that will be available in archive_dir
      # directory on localhost. You can specify option archive_destination which will force
      # routine to copy archive to destination host.
      # Steps:
      #   LOCALHOST
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      #   3) zfs send -rc %{snapshot_name} > %{tmp}     - Create temporary zfs archive
      #   ?) zonecfg -z %{zonename} export > %{tmp}     - Export zone config to temporary dir
      #   4) zip -j %{backup} [%{archive}, %{config}]   - Zip zfs archive with zone configuration
      #   5) move to final destination
      def self.backup_local_zone_zfs_archives(zone_name, archive_dir, opts = {})
        ###
        # OPTIONS
        logger              = opts[:logger] || SZMGMT.logger
        archive_destination = opts[:archive_destination]
        include_config      = opts[:include_config]
        temporary_dir       = opts[:temporary_dir] || '/var/tmp'
        current_time        = Time.now.to_i
        base_name           = "#{zone_name}_backup_#{current_time}"
        zone_config_name    = "#{base_name}.zonecfg"
        archive_name        = "#{base_name}.zfs.gz"
        backup_name         = "#{base_name}.zip"
        snapshot_name       = base_name

        temporary_backup    = File.join(temporary_dir, backup_name)
        temporary_archive   = File.join(temporary_dir, archive_name)
        zone_config_path    = File.join(temporary_dir, zone_config_name)

        files_to_pack       = [temporary_archive]
        cleaner             = SZONESCleanuper.new
        id                  = SZONESUtils.transaction_id
        logger.info("BACKUP (#{id}) - Backup of local zone '#{zone_name}' to #{archive_dir} has been initialized. Using ZFS archives...")
        # EXECUTION PHASE
        begin
          #
          # EXECUTED ON LOCALHOST
          #
          logger.info("BACKUP (#{id}) - Determine the zone volume of '#{zone_name}'...'")
          volume = SZONESBasicRoutines.determine_zone_volume(zone_name)
          logger.info("BACKUP (#{id}) - Creating recursive snapshot of local zone '#{zone_name}'...")
          SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, {:recursive => true}).exec
          cleaner.add_tmp_volume("#{volume}@#{snapshot_name}")
          logger.info("BACKUP (#{id}) - Creating zfs archive of local zone '#{zone_name}' on '#{temporary_archive}}'...")
          SZONESBasicZFSCommands.archive_dataset("#{volume}@#{snapshot_name}", temporary_archive, {:recursive => true, :complete => true}).exec
          cleaner.add_tmp_file(temporary_archive)

          if include_config
            logger.info("BACKUP (#{id}) - Exporting configuration of local zone '#{zone_name}' to ...")
            SZONESBasicZoneCommands.export_zone_to_file(zone_name, zone_config_path).exec
            cleaner.add_tmp_file(zone_config_path)
            files_to_pack << zone_config_path
          end
          logger.info("BACKUP (#{id}) - Creating zip #{temporary_backup} of files #{files_to_pack.join(', ')}...")
          SZONESBasicCommands.zip_files(temporary_backup, files_to_pack, {:junk_paths => true}).exec
          cleaner.add_tmp_file(temporary_backup) if archive_destination || temporary_backup != File.join(archive_dir, backup_name)

          if archive_destination
            # Copy to archive dir on remote host
            logger.info("BACKUP (#{id}) - Copying backup of zone '#{zone_name}' to '#{archive_destination[:host_name]}:#{archive_dir}'...")
            SZONESBasicCommands.copy_files_on_remote_host(temporary_backup, archive_destination, archive_dir).exec
          else
            # Copy to archive dir on localhost
            logger.info("BACKUP (#{id}) - Copying backup of zone '#{zone_name}' to 'localhost:#{archive_dir}'...")
            SZONESBasicCommands.copy_files(temporary_backup, archive_dir).exec unless temporary_backup == File.join(archive_dir, backup_name)
          end
        rescue Exceptions::SZONESError
          logger.info("BACKUP (#{id}) - Creating zfs archive of local zone '#{zone_name}' failed.")
          cleaner.cleanup_on_failure!
          false
        else
          logger.info("BACKUP (#{id}) - Creating zfs archive of local zone '#{zone_name}' succeeded.")
          true
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Backup remote zone using zfs archives method. It will
      # produce one archive that will be available on archive_dir
      # directory on remote host. You can specify option archive_destination which will force
      # routine to copy archive to destination host.
      # Steps:
      #   REMOTE HOST
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      #   3) zfs send -rc %{snapshot_name} > %{tmp}     - Create temporary zfs archive
      #   ?) zonecfg -z %{zonename} export > %{tmp}     - Export zone config to temporary dir
      #   4) zip -j %{backup} [%{archive}, %{config}]   - Zip zfs archive with zone configuration
      #   5) move to final destination
      def self.backup_remote_zone_zfs_archives(zone_name, remote_host_spec, archive_dir, opts = {})
        ###
        # OPTIONS
        logger              = opts[:logger] || SZMGMT.logger
        archive_destination = opts[:archive_destination]
        include_config      = opts[:include_config]
        temporary_dir       = opts[:temporary_dir] || '/var/tmp'
        current_time        = Time.now.to_i
        base_name           = "#{zone_name}_backup_#{current_time}"
        zone_config_name    = "#{base_name}.zonecfg"
        archive_name        = "#{base_name}.zfs.gz"
        backup_name         = "#{base_name}.zip"
        snapshot_name       = base_name

        temporary_backup    = File.join(temporary_dir, backup_name)
        temporary_archive   = File.join(temporary_dir, archive_name)
        zone_config_path    = File.join(temporary_dir, zone_config_name)

        files_to_pack       = [temporary_archive]
        cleaner             = SZONESCleanuper.new
        id                  = SZONESUtils.transaction_id
        logger.info("BACKUP (#{id}) - Backup of remote zone '#{remote_host_spec[:host_name]}:#{zone_name}' to #{archive_dir} has been initialized. Using ZFS archives...")
        begin
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            logger.info("BACKUP (#{id}) - Determine the zone volume of remote zone'#{zone_name}'...'")
            volume = SZONESBasicRoutines.determine_zone_volume(zone_name, ssh)
            logger.info("BACKUP (#{id}) - Creating recursive snapshot of remote zone '#{zone_name}' on '#{remote_host_spec[:host_name]}...")
            SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, {:recursive => true}).exec_ssh(ssh)
            cleaner.add_tmp_volume("#{volume}@#{snapshot_name}", remote_host_spec)
            logger.info("BACKUP (#{id}) - Creating zfs archive of remote zone '#{zone_name}' on '#{remote_host_spec[:host_name]}:#{temporary_archive}}'...")
            SZONESBasicZFSCommands.archive_dataset("#{volume}@#{snapshot_name}", temporary_archive, {:recursive => true, :complete => true}).exec_ssh(ssh)
            cleaner.add_tmp_file(temporary_archive, remote_host_spec)

            if include_config
              logger.info("BACKUP (#{id}) - Exporting configuration of local zone '#{zone_name}' to ...")
              SZONESBasicZoneCommands.export_zone_to_file(zone_name, zone_config_path).exec_ssh(ssh)
              cleaner.add_tmp_file(zone_config_path, remote_host_spec)
              files_to_pack << zone_config_path
            end

            logger.info("BACKUP (#{id}) - Creating zip #{temporary_backup} of files #{files_to_pack.join(', ')}...")
            SZONESBasicCommands.zip_files(temporary_backup, files_to_pack, {:junk_paths => true}).exec_ssh(ssh)
            cleaner.add_tmp_file(temporary_backup, remote_host_spec) if archive_destination || temporary_backup != File.join(archive_dir, backup_name)

            if archive_destination
              # Copy to archive dir on remote host
              logger.info("BACKUP (#{id}) - Copying backup of zone '#{zone_name}' to '#{archive_destination[:host_name]}:#{archive_dir}'...")
              SZONESBasicCommands.copy_files_on_remote_host(temporary_backup, archive_destination, archive_dir).exec_ssh(ssh)
            else
              # Copy to archive dir on localhost
              logger.info("BACKUP (#{id}) - Copying backup of zone '#{zone_name}' to '#{remote_host_spec[:host_name]}:#{archive_dir}'...")
              SZONESBasicCommands.copy_files(temporary_backup, archive_dir).exec_ssh(ssh) unless temporary_backup == File.join(archive_dir, backup_name)
            end
          end
        rescue Exceptions::SZONESError
          logger.info("BACKUP (#{id}) - Creating zfs archive of remote zone '#{remote_host_spec[:host_name]}:#{zone_name}' failed.")
          cleaner.cleanup_on_failure!
          false
        else
          logger.info("BACKUP (#{id}) - Creating zfs archive of remote zone '#{remote_host_spec[:host_name]}:#{zone_name}' succeeded.")
          true
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Backup local zone using unified archive method. It will
      # produce one archive that will be available on path_to_archive on localhost.
      # You can specify option archive_destination which will force
      # routine to copy archive to destination host.
      # Steps:
      #   LOCALHOST
      #   1) archiveadm create -z %{zone_name} %{uar}   - Create unified archive of zone to temporary dir
      #   2) move backup to destination
      def self.backup_local_zone_uar(zone_name, archive_dir, opts = {})
        ###
        # OPTIONS
        logger              = opts[:logger] || SZMGMT.logger
        archive_destination = opts[:archive_destination]
        temporary_dir       = opts[:temporary_dir] || '/var/tmp'
        current_time        = Time.now.to_i
        base_name           = "#{zone_name}_backup_#{current_time}"
        archive_name        = "#{base_name}.uar"
        temporary_archive   = File.join(temporary_dir, archive_name)
        cleaner             = SZONESCleanuper.new
        id                  = SZONESUtils.transaction_id
        logger.info("BACKUP (#{id}) - Backup of local zone '#{zone_name}' to #{archive_dir} has been initialized. Using UAR...")
        # EXECUTION PHASE
        begin
          #
          # EXECUTED ON LOCALHOST
          #
          logger.info("BACKUP (#{id}) - Creating UAR of local zone '#{zone_name}' to #{temporary_archive}...")
          SZONESBasicZoneCommands.create_unified_archive(zone_name, temporary_archive, {:recovery => true, :exclude => true}).exec
          cleaner.add_tmp_file(temporary_archive)
          if archive_destination
            # Copy to archive dir on remote host
            logger.info("BACKUP (#{id}) - Copying UAR of zone '#{zone_name}' to '#{archive_destination[:host_name]}:#{archive_dir}'...")
            SZONESBasicCommands.copy_files_on_remote_host(temporary_archive, archive_destination, archive_dir).exec
          else
            # Copy to archive dir on localhost
            logger.info("BACKUP (#{id}) - Copying UAR of zone '#{zone_name}' to 'localhost:#{archive_dir}'...")
            SZONESBasicCommands.copy_files(temporary_archive, archive_dir).exec unless temporary_archive == File.join(archive_dir, archive_name)
          end
        rescue Exceptions::SZONESError
          logger.info("BACKUP (#{id}) - Creating UAR of local zone '#{zone_name}' failed.")
          cleaner.cleanup_on_failure!
          false
        else
          logger.info("BACKUP (#{id}) - Creating UAR of local zone '#{zone_name}' succeed.")
          true
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Backup remote zone using unified archive method. It will
      # produce one archive that will be available on path_to_archive on remote host.
      # You can specify option archive_destination which will force
      # routine to copy archive to destination host.
      # Steps:
      #   REMOTE HOST
      #   1) archiveadm create -z %{zone_name} %{uar}   - Create unified archive of zone to temporary dir
      #   2) move backup to destination
      def self.backup_remote_zone_uar(zone_name, remote_host_spec, archive_dir, opts = {})
        ###
        # OPTIONS
        logger              = opts[:logger] || SZMGMT.logger
        archive_destination = opts[:archive_destination]
        temporary_dir       = opts[:temporary_dir] || '/var/tmp'
        current_time        = Time.now.to_i
        base_name           = "#{zone_name}_backup_#{current_time}"
        archive_name        = "#{base_name}.uar"
        temporary_archive   = File.join(temporary_dir, archive_name)
        cleaner             = SZONESCleanuper.new
        id                  = SZONESUtils.transaction_id
       logger.info("BACKUP (#{id}) - Backup of remote zone '#{remote_host_spec[:host_name]}:#{zone_name}' to #{archive_dir} has been initialized. Using UAR...")
        # EXECUTION PHASE
        begin
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            logger.info("BACKUP (#{id}) - Creating UAR of remote zone '#{remote_host_spec[:host_name]}:#{zone_name}' to #{temporary_archive}...")
            SZONESBasicZoneCommands.create_unified_archive(zone_name, temporary_archive, {:recovery => true, :exclude => true}).exec_ssh(ssh)
            cleaner.add_tmp_file(temporary_archive, remote_host_spec)
            if archive_destination
              # Copy to archive dir on remote host
              logger.info("BACKUP (#{id}) - Copying UAR of zone '#{zone_name}' to '#{archive_destination[:host_name]}:#{archive_dir}'...")
              SZONESBasicCommands.copy_files_on_remote_host(temporary_archive, archive_destination, archive_dir).exec_ssh(ssh)
            else
              # Copy to archive dir on localhost
              logger.info("BACKUP (#{id}) - Copying UAR of zone '#{zone_name}' to '#{remote_host_spec[:host_name]}:#{archive_dir}'...")
              SZONESBasicCommands.copy_files(temporary_archive, archive_dir).exec_ssh(ssh) unless temporary_archive == File.join(archive_dir, archive_name)
            end
          end
        rescue Exceptions::SZONESError
          logger.error("BACKUP (#{id}) - Creating UAR of remote zone '#{remote_host_spec[:host_name]}:#{zone_name}' failed.")
          cleaner.cleanup_on_failure!
          false
        else
          logger.info("BACKUP (#{id}) - Creating UAR of remote zone '#{remote_host_spec[:host_name]}:#{zone_name}' succeed.")
          true
        ensure
          cleaner.cleanup_temporary!
        end
      end
    end
  end
end