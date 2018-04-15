module SZMGMT
  module SZONES
    class SZONESMigrationRoutines
      # ADVANCED ROUTINES FOR ZONE MIGRATIONS
      # Migrate zone from localhost to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone using direct method.
      # Steps:
      #   LOCALHOST
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zoneadm -z %{zone_name} halt               - Halt the migrated zone
      #   3) zoneadm -z %{zone_name} detach             - Detach the migrated zone
      #   4) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      #   5) zfs send -rc %{snapshot_name}              - Send snapshot to given destination host
      #   6) zonecfg -z %{zonename} export > remote     - Export zone config to destination host
      #   DEST_HOST
      #   7) zonecfg -z %{dest_zonename} create         - Create zone configuration from exported zone
      #     ?) adjust zonepath                          - Adjust zonepath if it is diferent
      #   8) zoneadm -z %{dest_zonename} attach         - Attach zone to it's image
      #   LOCALHOST
      #   9) zonecfg -d %{zonename}                     - Delete zone configuration
      #  10) zfs destroy -r %{volume}                   - Destroy zone disk image
      def self.migrate_local_zone_directly(zone_name, destination_host_spec, opts = {})
        ###############################
        # OPTIONS
        destination_zone_name = opts[:destination_zone_name] || zone_name
        if opts[:destination_volume]
          destination_volume = File.join( opts[:destination_volume], destination_zone_name )
        end
        # PREPARATION PHASE
        cleaner           = SZONESCleanuper.new
        rollbacker        = SZONESRollbacker.new
        volume            = ''
        tmp_dir           = opts[:tmp_dir] || '/var/tmp/'
        current_time      = Time.now.to_i
        base_name         = "#{zone_name}_migration#{current_time}"
        snapshot_name     = base_name
        zone_config_path  = File.join(tmp_dir, "#{base_name}.zonecfg")
        id                = transaction_id
        SZMGMT.logger.info("MIGRATION (#{id}) -  Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' has been initialized (DIRECTLY) ...")
        # EXECUTION PHASE
        begin
          #
          # EXECUTED ON LOCAL MACHINE
          #
          SZMGMT.logger.info("MIGRATION (#{id}) - Determinig volume name of zone #{zone_name}...")
          volume = SZONESBasicRoutines.determine_zone_volume(zone_name)
          destination_volume ||= volume
          SZMGMT.logger.info("MIGRATION (#{id}) - Halting local zone #{zone_name}...")
          SZONESBasicZoneCommands.halt_zone(zone_name).exec
          rollbacker.add_zone_halt(zone_name)
          SZMGMT.logger.info("MIGRATION (#{id}) - Dettaching local zone #{zone_name}...")
          SZONESBasicZoneCommands.detach_zone(zone_name).exec
          rollbacker.add_zone_detach(zone_name)
          SZMGMT.logger.info("MIGRATION (#{id}) - Creating snapshot of local zone #{zone_name}...")
          SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true }).exec
          cleaner.add_tmp_volume("#{volume}@#{snapshot_name}")
          SZMGMT.logger.info("MIGRATION (#{id}) - Sending zone image to #{destination_host_spec[:host_name]}...")
          SZONESBasicZFSCommands.send_dataset("#{volume}@#{snapshot_name}",
                                              destination_host_spec[:host_name],
                                              destination_volume,
                                              { :recursive => true,
                                                :complete => true }).exec
          cleaner.add_persistent_volume(destination_volume, destination_host_spec)
          SZMGMT.logger.info("MIGRATION (#{id}) - Exporting zone configuration to #{destination_host_spec[:host_name]}:#{zone_config_path}...")
          SZONESBasicZoneCommands.export_zone_to_remote_file(zone_name, zone_config_path, destination_host_spec[:host_name]).exec
          cleaner.add_tmp_file(zone_config_path, destination_host_spec)
          #
          # EXECUTED ON DESTINATION HOST
          #
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Configuring zone #{destination_zone_name} on remote host...")
            SZONESBasicZoneCommands.configure_zone_from_file(destination_zone_name, zone_config_path).exec_ssh(ssh)
            cleaner.add_persistent_zone_configuration(destination_zone_name, destination_host_spec)
            if destination_volume != volume
              # we have to adjust zone path of the configuring zone
              SZMGMT.logger.info("MIGRATION (#{id}) - Adjusting the zonepath of #{destination_zone_name}...")
              mountpoint = SZONESBasicRoutines.determine_volume_mountpoint(destination_volume, ssh)
              SZONESBasicZoneCommands.configure_zone(destination_zone_name, {:commands => ["set zonepath=#{mountpoint}"]}).exec_ssh(ssh)
            end
            SZMGMT.logger.info("MIGRATION (#{id}) - Attaching zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.attach_zone(destination_zone_name).exec_ssh(ssh)
          end
          SZMGMT.logger.info("MIGRATION (#{id}) - Finished. Initializing local zone deletion...")
          #
          # EXECUTED ON LOCAL MACHINE
          #
          SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} congiguration on localhost...")
          SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ['delete -F']}).exec
          SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} disk image on localhost...")
          SZONESBasicZFSCommands.destroy_dataset(volume, {:recursive => true }).exec
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION (#{id}) - Migration (localhost->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull.")
          rollbacker.rollback!
          cleaner.cleanup_on_failure!
        else
          SZMGMT.logger.info("MIGRATION (#{id}) - Migration (localhost->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull.")
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Migrate zone from remote host to destination host. It will connect
      # to remote host with ssh and then transfer the zone. Then it will
      # connect to destination host and attach the zone using direct method.
      # Steps:
      #   REMOTE HOST
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zoneadm -z %{zone_name} halt               - Halt the migrated zone
      #   3) zoneadm -z %{zone_name} detach             - Detach the migrated zone
      #   4) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      #   5) zfs send -rc %{snapshot_name}              - Send snapshot to given destination host
      #   6) zonecfg -z %{zonename} export > remote     - Export zone config to destination host
      #   DESTINATION HOST
      #   7) zonecfg -z %{dest_zonename} create         - Create zone configuration from exported zone
      #     ?) adjust zonepath                          - Adjust zonepath if it is diferent
      #   8) zoneadm -z %{dest_zonename} attach         - Attach zone to it's image
      #   REMOTE HOST
      #   9) zonecfg -d %{zonename}                     - Delete zone configuration
      #  10) zfs destroy -r %{volume}                   - Destroy zone disk image
      def self.migrate_remote_zone_directly(zone_name, remote_host_spec, destination_host_spec, opts = {})
        ###############################
        # OPTIONS
        destination_zone_name = opts[:destination_zone_name] || zone_name
        if opts[:destination_volume]
          destination_volume = File.join( opts[:destination_volume], destination_zone_name )
        end
        # PREPARATION PHASE
        cleaner           = SZONESCleanuper.new
        rollbacker        = SZONESRollbacker.new
        volume            = ''
        tmp_dir           = opts[:tmp_dir] || '/var/tmp/'
        current_time      = Time.now.to_i
        base_name         = "#{zone_name}_migration#{current_time}"
        snapshot_name     = base_name
        zone_config_path  = File.join(tmp_dir, "#{base_name}.zonecfg")
        id                = transaction_id
        SZMGMT.logger.info("MIGRATION (#{id}) -  Migration (#{remote_host_spec[:host_name]} -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' has been initialized (DIRECTLY) ...")
        # EXECUTION PHASE
        begin
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Determinig volume name of zone #{zone_name}...")
            volume = SZONESBasicRoutines.determine_zone_volume(zone_name, ssh)
            destination_volume ||= volume
            SZMGMT.logger.info("MIGRATION (#{id}) - Halting zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.halt_zone(zone_name).exec_ssh(ssh)
            rollbacker.add_zone_halt(zone_name, remote_host_spec)
            SZMGMT.logger.info("MIGRATION (#{id}) - Dettaching zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.detach_zone(zone_name).exec_ssh(ssh)
            rollbacker.add_zone_detach(zone_name, remote_host_spec)
            SZMGMT.logger.info("MIGRATION (#{id}) - Creating snapshot of zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true }).exec_ssh(ssh)
            cleaner.add_tmp_volume("#{volume}@#{snapshot_name}", remote_host_spec)
            SZMGMT.logger.info("MIGRATION (#{id}) - Sending zone image from #{remote_host_spec[:host_name]} to #{destination_host_spec[:host_name]}...")
            SZONESBasicZFSCommands.send_dataset("#{volume}@#{snapshot_name}",
                                                destination_host_spec[:host_name],
                                                destination_volume,
                                                { :recursive => true,
                                                  :complete => true }).exec_ssh(ssh)
            cleaner.add_persistent_volume(destination_volume, destination_host_spec)
            SZMGMT.logger.info("MIGRATION (#{id}) - Exporting zone configuration from #{remote_host_spec[:host_name]} to #{destination_host_spec[:host_name]}:#{zone_config_path}...")
            SZONESBasicZoneCommands.export_zone_to_remote_file(zone_name, zone_config_path, destination_host_spec[:host_name]).exec_ssh(ssh)
            cleaner.add_tmp_file(zone_config_path, destination_host_spec)
          end
          #
          # EXECUTED ON DESTINATION HOST
          #
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Configuring zone #{destination_zone_name} on remote host...")
            SZONESBasicZoneCommands.configure_zone_from_file(destination_zone_name, zone_config_path).exec_ssh(ssh)
            cleaner.add_persistent_zone_configuration(destination_zone_name, destination_host_spec)
            if destination_volume != volume
              # we have to adjust zone path of the configuring zone
              SZMGMT.logger.info("MIGRATION (#{id}) - Adjusting the zonepath of #{destination_zone_name}...")
              mountpoint = SZONESBasicRoutines.determine_volume_mountpoint(destination_volume, ssh)
              SZONESBasicZoneCommands.configure_zone(destination_zone_name, {:commands => ["set zonepath=#{mountpoint}"]}).exec_ssh(ssh)
            end
            SZMGMT.logger.info("MIGRATION (#{id}) - Attaching zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.attach_zone(destination_zone_name).exec_ssh(ssh)
          end
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} congiguration on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ['delete -F']}).exec_ssh(ssh)
            SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} disk image on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZFSCommands.destroy_dataset(volume, {:recursive => true }).exec_ssh(ssh)
          end
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION (#{id}) - Migration (localhost->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull.")
          rollbacker.rollback!
          cleaner.cleanup_on_failure!
        else
          SZMGMT.logger.info("MIGRATION (#{id}) - Migration (localhost->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull.")
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Migrate zone from localhost to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone. Using ZFS archives method
      # Steps:
      #   LOCALHOST
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zoneadm -z %{zone_name} halt               - Halt the migrated zone
      #   3) zonecfg -z %{zone_name} export > %{file}   - Export zone configuration to file
      #   4) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      #   5) zfs send -rc %{snapshot_name}              - Send snapshot to given destination host by archive
      #   6) zonecfg -z %{zonename} export > remote     - Export zone config to destination host
      #   DESTINATION HOST
      #   7) zonecfg -z %{destzonename} create          - Create zone configuration from exported zone
      #     ?) adjust zonepath                          - Adjust zonepath if it is diferent
      #   8) zoneadm -z %{destzonename} attach -a %{ar} - Attach zone to it's image
      #   LOCALHOST
      #   9) zonecfg -d %{zonename}                     - Delete zone configuration
      #  10) zfs destroy -r %{volume}                   - Destroy zone disk image
      def self.migrate_local_zone_zfs_archives(zone_name, destination_host_spec, opts = {})
        ###############################
        # OPTIONS
        destination_zone_name = opts[:destination_zone_name] || zone_name
        if opts[:destination_zonepath]
          destination_zonepath = File.join( opts[:destination_zonepath], destination_zone_name )
        end
        # PREPARATION PHASE
        cleaner           = SZONESCleanuper.new
        rollbacker        = SZONESRollbacker.new
        tmp_dir           = opts[:tmp_dir] || '/var/tmp/'
        current_time      = Time.now.to_i
        base_name         = "#{zone_name}_migration#{current_time}"
        snapshot_name     = base_name
        zone_config_path  = File.join(tmp_dir, "#{base_name}.zonecfg")
        archive_path      = File.join(tmp_dir, "#{base_name}.zfs.gz")
        id = transaction_id
        SZMGMT.logger.info("MIGRATION (#{id}) -  Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' has been initialized (ZFS) ...")
        # EXECUTION PHASE
        begin
          #
          # EXECUTED ON LOCAL MACHINE
          #
          SZMGMT.logger.info("MIGRATION (#{id}) - Determinig volume name of local zone #{zone_name}...")
          volume = SZONESBasicRoutines.determine_zone_volume(zone_name)
          SZMGMT.logger.info("MIGRATION (#{id}) - Halting local zone #{zone_name}...")
          SZONESBasicZoneCommands.halt_zone(zone_name).exec
          rollbacker.add_zone_halt(zone_name)
          SZMGMT.logger.info("MIGRATION (#{id}) - Dettaching local zone #{zone_name}...")
          SZONESBasicZoneCommands.detach_zone(zone_name).exec
          rollbacker.add_zone_detach(zone_name)
          SZMGMT.logger.info("MIGRATION (#{id}) - Creating snapshot of local zone #{zone_name}...")
          SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true }).exec
          cleaner.add_tmp_volume("#{volume}@#{snapshot_name}")
          SZMGMT.logger.info("MIGRATION (#{id}) - Sending archived zone image to #{destination_host_spec[:host_name]}:#{archive_path}...")
          SZONESBasicZFSCommands.archive_dataset_on_remote("#{volume}@#{snapshot_name}",
                                                           archive_path,
                                                           destination_host_spec[:host_name],
                                                           { :recursive => true, :complete => true} ).exec
          cleaner.add_tmp_file(archive_path, destination_host_spec)
          SZMGMT.logger.info("MIGRATION (#{id}) - Exporting zone configuration to #{destination_host_spec[:host_name]}:#{zone_config_path}...")
          SZONESBasicZoneCommands.export_zone_to_remote_file(zone_name, zone_config_path, destination_host_spec[:host_name]).exec
          cleaner.add_tmp_file(zone_config_path, destination_host_spec)
          #
          # EXECUTED ON DESTINATION HOST
          #
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Configuring zone #{destination_zone_name} on remote host...")
            SZONESBasicZoneCommands.configure_zone_from_file(destination_zone_name, zone_config_path).exec_ssh(ssh)
            cleaner.add_persistent_zone_configuration(destination_zone_name, destination_host_spec)
            if destination_zonepath
              # we have to adjust zone path of the configuring zone
              SZMGMT.logger.info("MIGRATION (#{id}) - Adjusting the zonepath of #{destination_zone_name}...")
              SZONESBasicZoneCommands.configure_zone(destination_zone_name, {:commands => ["set zonepath=#{destination_zonepath}"]}).exec_ssh(ssh)
            end
            SZMGMT.logger.info("MIGRATION (#{id}) - Attaching zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.attach_zone(destination_zone_name, { :path_to_archive => archive_path }).exec_ssh(ssh)
          end
          #
          # EXECUTED ON LOCAL MACHINE
          #
          SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} congiguration on localhost...")
          SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ['delete -F']}).exec
          SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} disk image on localhost...")
          SZONESBasicZFSCommands.destroy_dataset(volume, {:recursive => true }).exec
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION (#{id}) - Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull.")
          rollbacker.rollback!
          cleaner.cleanup_on_failure!
        else
          SZMGMT.logger.info("MIGRATION (#{id}) - Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull.")
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Migrate zone from localhost to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone. Using ZFS archives method
      # Steps:
      #   REMOTE HOST
      #   1) determine_zone_volume (routine)            - Determine volume of the migrated zone
      #   2) zoneadm -z %{zone_name} halt               - Halt the migrated zone
      #   3) zonecfg -z %{zone_name} export > %{file}   - Export zone configuration to file
      #   4) zfs snapshot -r %{snapshot_name}           - Create recursive snapshot for given volume
      #   5) zfs send -rc %{snapshot_name}              - Send snapshot to given destination host by archive
      #   6) zonecfg -z %{zonename} export > remote     - Export zone config to destination host
      #   DESTINATION HOST
      #   7) zonecfg -z %{destzonename} create          - Create zone configuration from exported zone
      #     ?) adjust zonepath                          - Adjust zonepath if it is diferent
      #   8) zoneadm -z %{destzonename} attach -a %{ar} - Attach zone to it's image
      #   REMOTE HOST
      #   9) zonecfg -d %{zonename}                     - Delete zone configuration
      #  10) zfs destroy -r %{volume}                   - Destroy zone disk image
      def self.migrate_remote_zone_zfs_archives(zone_name, remote_host_spec, destination_host_spec, opts = {})
        ###############################
        # OPTIONS
        destination_zone_name = opts[:destination_zone_name] || zone_name
        if opts[:destination_zonepath]
          destination_zonepath = File.join( opts[:destination_zonepath], destination_zone_name )
        end
        # PREPARATION PHASE
        cleaner           = SZONESCleanuper.new
        rollbacker        = SZONESRollbacker.new
        volume            = ''
        tmp_dir           = opts[:tmp_dir] || '/var/tmp/'
        current_time      = Time.now.to_i
        base_name         = "#{zone_name}_migration#{current_time}"
        snapshot_name     = base_name
        zone_config_path  = File.join(tmp_dir, "#{base_name}.zonecfg")
        archive_path      = File.join(tmp_dir, "#{base_name}.zfs.gz")
        id = transaction_id
        SZMGMT.logger.info("MIGRATION (#{id}) - Migration (#{remote_host_spec[:host_name]}->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' has been initialized (ZFS)...")
        # EXECUTION PHASE
        begin
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Determinig volume name of zone #{zone_name}...")
            volume = SZONESBasicRoutines.determine_zone_volume(zone_name, ssh)
            SZMGMT.logger.info("MIGRATION (#{id}) - Halting zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.halt_zone(zone_name).exec_ssh(ssh)
            rollbacker.add_zone_halt(zone_name, remote_host_spec)
            SZMGMT.logger.info("MIGRATION (#{id}) - Dettaching zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.detach_zone(zone_name).exec_ssh(ssh)
            rollbacker.add_zone_detach(zone_name, remote_host_spec)
            SZMGMT.logger.info("MIGRATION (#{id}) - Creating snapshot of zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true }).exec_ssh(ssh)
            cleaner.add_tmp_volume("#{volume}@#{snapshot_name}", remote_host_spec)

            SZMGMT.logger.info("MIGRATION (#{id}) - Sending archived zone image from #{remote_host_spec[:host_name]} to #{destination_host_spec[:host_name]}:#{archive_path}...")
            SZONESBasicZFSCommands.archive_dataset_on_remote("#{volume}@#{snapshot_name}",
                                                             archive_path,
                                                             destination_host_spec[:host_name],
                                                             { :recursive => true, :complete => true} ).exec_ssh(ssh)
            cleaner.add_tmp_file(archive_path, destination_host_spec)
            SZMGMT.logger.info("MIGRATION (#{id}) - Exporting zone configuration from #{remote_host_spec[:host_name]} to #{destination_host_spec[:host_name]}:#{zone_config_path}...")
            SZONESBasicZoneCommands.export_zone_to_remote_file(zone_name, zone_config_path, destination_host_spec[:host_name]).exec_ssh(ssh)
            cleaner.add_tmp_file(zone_config_path, destination_host_spec)
          end
          #
          # EXECUTED ON DESTINATION HOST
          #
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Configuring zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.configure_zone_from_file(destination_zone_name, zone_config_path).exec_ssh(ssh)
            cleaner.add_persistent_zone_configuration(destination_zone_name, destination_host_spec)
            if destination_zonepath
              # we have to adjust zone path of the configuring zone
              SZMGMT.logger.info("MIGRATION (#{id}) - Adjusting the zonepath of #{destination_zone_name}...")
              SZONESBasicZoneCommands.configure_zone(destination_zone_name, {:commands => ["set zonepath=#{destination_zonepath}"]}).exec_ssh(ssh)
            end
            SZMGMT.logger.info("MIGRATION (#{id}) - Attaching zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.attach_zone(destination_zone_name, { :path_to_archive => archive_path }).exec_ssh(ssh)
          end
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} congiguration on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ['delete -F']}).exec_ssh(ssh)
            SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} disk image on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZFSCommands.destroy_dataset(volume, {:recursive => true }).exec_ssh(ssh)
          end
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION (#{id}) - Migration (#{remote_host_spec[:host_name]}->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull.")
          rollbacker.rollback!
          cleaner.cleanup_on_failure!
        else
          SZMGMT.logger.info("MIGRATION (#{id}) - Migration (#{remote_host_spec[:host_name]}->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull.")
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Migrate zone from localhost to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone. Using Unified archives method
      # Steps:
      #   LOCALHOST
      #   1) archiveadm -z %{zone_name} -re %{archive}  - Create unified archive from zone
      #   2) scp %{archive} %{hostname}:%{archive}      - Copy the archive with zone to another host
      #   DESTINATION HOST
      #   3) zonecfg -z %{destzonename} create          - Create zone configuration from UAR
      #     ?) adjust zonepath                          - Adjust zonepath if it is diferent
      #   4) zoneadm -z %{destzonename} attach -a %{ar} - Attach zone to it's image from UAR
      #   LOCALHOST
      #   5) zonecfg -d %{zonename}                     - Delete zone configuration
      #   6) zfs destroy -r %{volume}                   - Destroy zone disk image
      def self.migrate_local_zone_uar(zone_name, destination_host_spec, opts = {})
        # OPTIONS
        destination_zone_name = opts[:destination_zone_name] || zone_name
        if opts[:destination_zonepath]
          destination_zonepath = File.join( opts[:destination_zonepath], destination_zone_name )
        end
        # PREPARATION PHASE
        cleaner           = SZONESCleanuper.new
        rollbacker        = SZONESRollbacker.new
        tmp_dir           = opts[:tmp_dir] || '/var/tmp/'
        current_time      = Time.now.to_i
        base_name         = "#{zone_name}_migration#{current_time}"
        path_to_archive   = File.join(tmp_dir, "#{base_name}.uar")
        id = transaction_id
        SZMGMT.logger.info("MIGRATION (#{id}) -  Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' has been initialized (UAR) ...")
        # EXECUTIUON PHASE
        begin
          #
          # EXECUTED ON LOCAL MACHINE
          #
          SZMGMT.logger.info("MIGRATION (#{id}) - Creating unified archive on localhost #{path_to_archive}...")
          SZONESBasicZoneCommands.create_unified_archive(zone_name, path_to_archive, {:exclude => true, :recovery => true}).exec
          cleaner.add_tmp_file(path_to_archive)
          SZMGMT.logger.info("MIGRATION (#{id}) - Coping unified archive #{path_to_archive} to remote host #{destination_host_spec[:host_name]}...")
          SZONESBasicCommands.copy_files_on_remote_host(path_to_archive, destination_host_spec, tmp_dir).exec
          cleaner.add_tmp_file(path_to_archive, destination_host_spec)
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Configuring zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.configure_zone(destination_zone_name, {:commands => ["create -a #{path_to_archive}"]}).exec_ssh(ssh)
            cleaner.add_persistent_zone_configuration(destination_zone_name, destination_host_spec)
            if destination_zonepath
              # we have to adjust zone path of the configuring zone
              SZMGMT.logger.info("MIGRATION (#{id}) - Adjusting the zonepath of #{destination_zone_name}...")
              SZONESBasicZoneCommands.configure_zone(destination_zone_name, {:commands => ["set zonepath=#{destination_zonepath}"]}).exec_ssh(ssh)
            end
            SZMGMT.logger.info("MIGRATION (#{id}) - Attaching zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.attach_zone(destination_zone_name, {:path_to_archive => path_to_archive}).exec_ssh(ssh)
          end
          #
          # EXECUTED ON LOCAL MACHINE
          #
          SZMGMT.logger.info("MIGRATION (#{id}) - Determining zone volume of zone #{zone_name} on localhost...")
          volume = SZONESBasicRoutines.determine_zone_volume(zone_name)
          SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} congiguration on localhost...")
          SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ['delete -F']}).exec
          SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} disk image on localhost...")
          SZONESBasicZFSCommands.destroy_dataset(volume, {:recursive => true }).exec
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION (#{id}) - Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull (UAR).")
          rollbacker.rollback!
          cleaner.cleanup_on_failure!
        else
          SZMGMT.logger.info("MIGRATION (#{id}) - Migration (localhost -> #{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull (UAR).")
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Migrate zone from remote host to destination host. It will transfer
      # the zone to destination host and Then it will connect to
      # the destination host and attach the zone. Using Unified archives method
      # Steps:
      #   REMOTE HOST
      #   1) archiveadm -z %{zone_name} -re %{archive}  - Create unified archive from zone
      #   2) scp %{archive} %{hostname}:%{archive}      - Copy the archive with zone to another host
      #   DESTINATION HOST
      #   3) zonecfg -z %{destzonename} create          - Create zone configuration from UAR
      #     ?) adjust zonepath                          - Adjust zonepath if it is diferent
      #   4) zoneadm -z %{destzonename} attach -a %{ar} - Attach zone to it's image from UAR
      #   REMOTE HOST
      #   5) zonecfg -d %{zonename}                     - Delete zone configuration
      #   6) zfs destroy -r %{volume}                   - Destroy zone disk image
      def self.migrate_remote_zone_uar(zone_name, remote_host_spec, destination_host_spec, opts = {})
        # OPTIONS
        destination_zone_name = opts[:destination_zone_name] || zone_name
        if opts[:destination_zonepath]
          destination_zonepath = File.join( opts[:destination_zonepath], destination_zone_name )
        end
        # PREPARATION PHASE
        cleaner           = SZONESCleanuper.new
        rollbacker        = SZONESRollbacker.new
        tmp_dir           = opts[:tmp_dir] || '/var/tmp/'
        current_time      = Time.now.to_i
        base_name         = "#{zone_name}_migration#{current_time}"
        path_to_archive   = File.join(tmp_dir, "#{base_name}.uar")
        id = transaction_id
        SZMGMT.logger.info("MIGRATION (#{id}) - Migration (#{remote_host_spec[:host_name]}->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' has been initialized (UAR)...")
        # EXECUTIUON PHASE
        begin
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Creating unified archive on #{remote_host_spec[:host_name]} #{path_to_archive}...")
            SZONESBasicZoneCommands.create_unified_archive(zone_name, path_to_archive, {:exclude => true, :recovery => true}).exec_ssh(ssh)
            cleaner.add_tmp_file(path_to_archive)
            SZMGMT.logger.info("MIGRATION (#{id}) - Coping unified archive #{path_to_archive} from #{remote_host_spec[:host_name]} to remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicCommands.copy_files_on_remote_host(path_to_archive, destination_host_spec, tmp_dir).exec_ssh(ssh)
            cleaner.add_tmp_file(path_to_archive, destination_host_spec)
          end
          #
          # EXECUTED ON DESTINATION HOST
          #
          Net::SSH.start(destination_host_spec[:host_name], destination_host_spec[:user], destination_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Configuring zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.configure_zone(destination_zone_name, {:commands => ["create -a #{path_to_archive}"]}).exec_ssh(ssh)
            cleaner.add_persistent_zone_configuration(destination_zone_name, destination_host_spec)
            if destination_zonepath
              # we have to adjust zone path of the configuring zone
              SZMGMT.logger.info("MIGRATION (#{id}) - Adjusting the zonepath of #{destination_zone_name}...")
              SZONESBasicZoneCommands.configure_zone(destination_zone_name, {:commands => ["set zonepath=#{destination_zonepath}"]}).exec_ssh(ssh)
            end
            SZMGMT.logger.info("MIGRATION (#{id}) - Attaching zone #{destination_zone_name} on remote host #{destination_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.attach_zone(destination_zone_name, {:path_to_archive => path_to_archive}).exec_ssh(ssh)
          end
          #
          # EXECUTED ON REMOTE HOST
          #
          Net::SSH.start(remote_host_spec[:host_name], remote_host_spec[:user], remote_host_spec.to_h) do |ssh|
            SZMGMT.logger.info("MIGRATION (#{id}) - Determining zone volume of zone #{zone_name} on localhost...")
            volume = SZONESBasicRoutines.determine_zone_volume(zone_name, ssh)
            SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} congiguration on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ['delete -F']}).exec_ssh(ssh)
            SZMGMT.logger.info("MIGRATION (#{id}) - Deleteting zone #{zone_name} disk image on host #{remote_host_spec[:host_name]}...")
            SZONESBasicZFSCommands.destroy_dataset(volume, {:recursive => true }).exec_ssh(ssh)
          end
        rescue Exceptions::SZONESError
          SZMGMT.logger.error("MIGRATION (#{id}) - Migration (#{remote_host_spec[:host_name]}->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' wasn't sucessfull (UAR).")
        else
          SZMGMT.logger.info("MIGRATION (#{id}) - Migration (#{remote_host_spec[:host_name]}->#{destination_host_spec[:host_name]}) of zone '#{zone_name}' was sucessfull (UAR).")
        ensure
          cleaner.cleanup_temporary!
        end
      end

      private
      # Generator of transaction id of length 8
      def self.transaction_id
        length = 8
        rand(36**length).to_s(36)
      end
    end
  end
end