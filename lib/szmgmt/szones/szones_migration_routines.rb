module SZMGMT
  module SZONES
    class SZONESMigrationRoutines
      # ADVANCED ROUTINES FOR ZONE MIGRATIONS
      # Migrate zone from localhost to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone.
      # Steps:
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zoneadm -z %{zone_name} halt               - Halt the migrated zone
      #   3) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      def self.migrate_local_zone_directly(zone_name, destination_host_spec)
        SZMGMT.logger.info("Initializing zone migration routine for zone #{zone_name} ...")
        # Step 1 - Determine volume of the migrated zone
        volume = SZONESBasicRoutines.determine_zone_volume(zone_name)
        # Step 2 - Halt the zone
        SZONESBasicZoneCommands.halt_zone(zone_name).exec
        # Step 3 - Create snapshot
        snapshot_name = "#{zone_name}_migration_#{Time.now.to_i}"
        SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true }).exec
        SZONESBasicZFSCommands.send_dataset("#{volume}@#{snapshot_name}",
                                            destination_host_spec[:host_name],
                                            { :recursive => true,
                                              :complete => true }).exec


      end
      # Migrate zone from remote host to destination host. It will connect
      # to remote host with ssh and then transfer the zone. Then it will
      # connect to destination host and attach the zone.
      # Steps:
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zoneadm -z %{zone_name} halt               - Halt the migrated zone
      #   3) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      def self.migrate_remote_zone_directly(zone_name, remote_host_spec, destination_host_spec)
        # Create ssh connection to remote host
        Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec) do |ssh|
          # Step 1 - Determine volume of the migrated zone
          volume = SZONESBasicRoutines.determine_zone_volume(zone_name, ssh)
          # Step 2 - Halt the
          SZONESBasicZoneCommands.halt_zone(zone_name).exec_ssh(ssh)
        end

      end

      # Migrate zone from localhost to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone. Using ZFS archives method
      # Steps:
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zoneadm -z %{zone_name} halt               - Halt the migrated zone
      #   3) zonecfg -z %{zone_name} export > %{file}   - Export zone configuration to file
      #   4) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      #   5)
      def self.migrate_local_zone_zfs_archives(zone_name, destination_host_spec, update = false)
        SZMGMT.logger.info("Initializing zone migration routine for zone #{zone_name} ...")
        # PREPARATION
        cleaner = SZONESCleanuper.new
        current_time = Time.now.to_i
        zone_config_path = "/var/tmp/#{zone_name}_migration_#{current_time}.zonecfg"
        snapshot_name = "#{zone_name}_migration_#{current_time}"
        archive_name = "/var/tmp/#{snapshot_name}.zfs.gz"
        begin
          volume = SZONESBasicRoutines.determine_zone_volume(zone_name)
          SZONESBasicZoneCommands.halt_zone(zone_name).exec
          SZONESBasicZoneCommands.export_zone_to_remote_file(zone_name, zone_config_path, destination_host_spec[:host_name]).exec
          cleaner.add_file(zone_config_path, destination_host_spec)
          SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true }).exec
          cleaner.add_volume("#{volume}@#{snapshot_name}")
          SZONESBasicZFSCommands.archive_dataset_on_remote("#{volume}@#{snapshot_name}",
                                                           archive_name,
                                                           destination_host_spec[:host_name],
                                                           { :recursive => true, :complete => true} ).exec
          cleaner.add_file(archive_name, destination_host_spec)
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec.to_h) do |ssh|
            SZONESBasicZoneCommands.configure_zone_from_file(zone_name, zone_config_path).exec_ssh(ssh)
            SZONESBasicZoneCommands.attach_zone(zone_name, {:update => update, :path_to_archive => archive_name }).exec_ssh(ssh)
          end
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION - Migration (localhost->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull.")
        else
          SZMGMT.logger.info("MIGRATION - Migration (localhost->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull.")
        ensure
          cleaner.cleanup!
        end
      end
      # Migrate zone from localhost to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone. Using ZFS archives method
      # Steps:
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zoneadm -z %{zone_name} halt               - Halt the migrated zone
      #   3) zonecfg -z %{zone_name} export > %{file}   - Export zone configuration to file
      #   4) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      #   5)
      def self.migrate_remote_zone_zfs_archives(zone_name, remote_host_spec, destination_host_spec, update = false)
        SZMGMT.logger.info("Initializing zone migration routine for zone #{zone_name} ...")
        # PREPARATION PHASE
        cleaner           = SZONESCleanuper.new
        current_time      = Time.now.to_i
        zone_config_path  = "/var/tmp/#{zone_name}_migration_#{current_time}.zonecfg"
        snapshot_name     = "#{zone_name}_migration_#{current_time}"
        archive_name      = "/var/tmp/#{snapshot_name}.zfs.gz"
        # EXECUTION PHASE
        begin
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            volume = SZONESBasicRoutines.determine_zone_volume(zone_name, ssh)
            SZONESBasicZoneCommands.halt_zone(zone_name).exec_ssh(ssh)
            SZONESBasicZoneCommands.export_zone_to_remote_file(zone_name, zone_config_path, destination_host_spec[:host_name]).exec_ssh(ssh)
            cleaner.add_file(zone_config_path, destination_host_spec)
            SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true }).exec_ssh(ssh)
            cleaner.add_volume("#{volume}@#{snapshot_name}", remote_host_spec)
            SZONESBasicZFSCommands.archive_dataset_on_remote("#{volume}@#{snapshot_name}",
                                                             archive_name,
                                                             destination_host_spec[:host_name],
                                                             { :recursive => true, :complete => true} ).exec_ssh(ssh)
            cleaner.add_file(archive_name, destination_host_spec)
          end
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec.to_h) do |ssh|
            SZONESBasicZoneCommands.configure_zone_from_file(zone_name, zone_config_path).exec_ssh(ssh)
            SZONESBasicZoneCommands.attach_zone(zone_name, {:update => update, :path_to_archive => archive_name }).exec_ssh(ssh)
          end
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION - Migration (#{remote_host_spec[:host_name]}->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull.")
        else
          SZMGMT.logger.info("MIGRATION - Migration (#{remote_host_spec[:host_name]}->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull.")
        ensure
          cleaner.cleanup!
        end
      end

      # Migrate zone from localhost to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone. Using Unified archives method
      # Steps:
      #   1) archiveadm -z %{zone_name} -re %{archive}  - Create unified archive from zone
      #   2) scp %{archive} %{hostname}:%{archive}      - Copy the archive with zone to another host
      #   3)
      def self.migrate_local_zone_uar(zone_name, destination_host_spec)
        SZMGMT.logger.info("MIGRATION -  Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' has been initialized (UAR) ...")
        # PREPARATION PHASE
        tmp_dir         = '/var/tmp'
        cleaner         = SZONESCleanuper.new
        current_time    = Time.now.to_i
        archive_name    = "#{zone_name}_migration#{current_time}.uar"
        path_to_archive = File.join(tmp_dir, archive_name)
        # EXECUTIUON PHASE
        begin
          SZONESBasicZoneCommands.create_unified_archive(zone_name, path_to_archive, {:exclude => true, :recovery => true}).exec
          cleaner.add_file(path_to_archive)
          SZONESBasicCommands.copy_files_on_remote_host(path_to_archive, destination_host_spec, tmp_dir).exec
          cleaner.add_file(path_to_archive, destination_host_spec)
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec) do |ssh|
            SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ["create -a #{path_to_archive}"]}).exec_ssh(ssh)
            SZONESBasicZoneCommands.attach_zone(zone_name, {:path_to_archive => path_to_archive})
          end
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION - Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull (UAR).")
        else
          SZMGMT.logger.info("MIGRATION - Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull (UAR).")
        ensure
          cleaner.cleanup!
        end
      end

      def self.migrate_remote_zone_uar(zone_name, remote_host_spec, destination_host_spec)
        SZMGMT.logger.info("MIGRATION -  Migration (#{remote_host_spec[:host_name]} -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' has been initialized (UAR) ...")
      end
    end
  end
end