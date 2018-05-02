module SZMGMT
  module SZONES
    class SZONESDeploymentSubroutines

      def self.deploy_zone_from_files(zone_name, path_to_zonecfg, opts = {}, ssh = nil, host_spec = {:host_name => 'localhost'})
        cleaner = opts[:cleaner]
        logger  = opts[:logger] || SZMGMT.logger
        logger.info("DEPLOY (#{opts[:id]}) -      Configuring zone #{zone_name}...")
        logger.info("DEPLOY (#{opts[:id]}) -             config: #{path_to_zonecfg}")
        configure = SZONESBasicZoneCommands.configure_zone_from_file(zone_name, path_to_zonecfg)
        ssh ? configure.exec_ssh(ssh) : configure.exec
        cleaner.add_persistent_zone_configuration(zone_name, host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Configuration of zone #{zone_name} created.")
        # Testing zonepath
        zonecfg = SZONESBasicZoneCommands.configure_zone(zone_name, { :commands => ['info zonepath'] })
        ssh ? zonecfg.exec_ssh(ssh) : zonecfg.exec
        # Parse output of zonecfg command in step 1) that should
        # return zonepath in format 'zonepath: /system/zones/Test\n'
        zonepath = zonecfg.stdout.chomp("\n").split(' ').last
        if zonepath.split('/').last != zone_name
          tokens = zonepath.split('/')
          tokens[-1] = zone_name
          opts[:zonepath] = tokens.join('/') unless opts[:zonepath]
        end

        if opts[:zonepath]
          logger.info("DEPLOY (#{opts[:id]}) -      Adjusting the zonepath of zone #{zone_name}...")
          adjust = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ["set zonepath=#{opts[:zonepath]}"]})
          ssh ? adjust.exec_ssh(ssh) : adjust.exec
          logger.info("DEPLOY (#{opts[:id]}) -      Zonepath of zone #{zone_name} adjusted.")
        end
        logger.info("DEPLOY (#{opts[:id]}) -      Installing zone #{zone_name}...")
        logger.info("DEPLOY (#{opts[:id]}) -           manifest: #{opts[:path_to_manifest]}") if opts[:path_to_manifest]
        logger.info("DEPLOY (#{opts[:id]}) -            profile: #{opts[:path_to_profile]}") if opts[:path_to_profile]
        cleaner.add_persistent_zone_installation(zone_name, host_spec)
        options = {}
        options[:path_to_manifest] = opts[:path_to_manifest] if opts[:path_to_manifest]
        options[:path_to_profile] = opts[:path_to_profile] if opts[:path_to_profile]
        install = SZONESBasicZoneCommands.install_zone(zone_name, options)
        ssh ? install.exec_ssh(ssh) : install.exec
        logger.info("DEPLOY (#{opts[:id]}) -      Installation of zone #{zone_name} finished.")
      end

      def self.deploy_zone_from_local_zone(zone_name, source_zone_name, opts = {}, ssh = nil, host_spec = {:host_name => 'localhost'} )
        cleaner = opts[:cleaner]
        logger  = opts[:logger] || SZMGMT.logger
        logger.info("DEPLOY (#{opts[:id]}) -      Configuring zone #{zone_name} from srouce zone #{source_zone_name}...")
        logger.info("DEPLOY (#{opts[:id]}) -             Cloning configuration from #{source_zone_name}...")
        configure = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ["create -t #{source_zone_name}"]})
        ssh ? configure.exec_ssh(ssh) : configure.exec
        cleaner.add_persistent_zone_configuration(zone_name, host_spec)
        # Testing zonepath
        zonecfg = SZONESBasicZoneCommands.configure_zone(zone_name, { :commands => ['info zonepath'] })
        ssh ? zonecfg.exec_ssh(ssh) : zonecfg.exec
        # Parse output of zonecfg command in step 1) that should
        # return zonepath in format 'zonepath: /system/zones/Test\n'
        zonepath = zonecfg.stdout.chomp("\n").split(' ').last
        if zonepath.split('/').last != zone_name
          tokens = zonepath.split('/')
          tokens[-1] = zone_name
          opts[:zonepath] = tokens.join('/') unless opts[:zonepath]
        end

        logger.info("DEPLOY (#{opts[:id]}) -      Configuration of zone #{zone_name} created.")
        if opts[:zonepath]
         logger.info("DEPLOY (#{opts[:id]}) -      Adjusting the zonepath of zone #{zone_name}...")
          adjust = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ["set zonepath=#{opts[:zonepath]}"]})
          ssh ? adjust.exec_ssh(ssh) : adjust.exec
          logger.info("DEPLOY (#{opts[:id]}) -      Zonepath of zone #{zone_name} adjusted.")
        end
        logger.info("DEPLOY (#{opts[:id]}) -      Cloning zone #{zone_name} from source zone #{source_zone_name}...")
        logger.info("DEPLOY (#{opts[:id]}) -              type: clone.")
        cleaner.add_persistent_zone_installation(zone_name, host_spec)
        clone = SZONESBasicZoneCommands.clone_zone(zone_name, source_zone_name)
        ssh ? clone.exec_ssh(ssh) : clone.exec
        logger.info("DEPLOY (#{opts[:id]}) -      Cloning zone #{zone_name} from source zone #{source_zone_name} finished.")
      end

      def self.deploy_zone_from_uar(zone_name, path_to_uar, opts = {}, ssh = nil, host_spec = {:host_name => 'localhost'})
        cleaner = opts[:cleaner]
        logger  = opts[:logger] || SZMGMT.logger
        logger.info("DEPLOY (#{opts[:id]}) -      Configuring zone #{zone_name} from UAR...")
        logger.info("DEPLOY (#{opts[:id]}) -                uar: #{path_to_uar}...")
        configure = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ["create -a #{path_to_uar}"]})
        ssh ? configure.exec_ssh(ssh) : configure.exec
        cleaner.add_persistent_zone_configuration(zone_name, host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Configuration of zone #{zone_name} created.")
        if opts[:zonepath]
          logger.info("DEPLOY (#{opts[:id]}) -      Adjusting the zonepath of zone #{zone_name}...")
          adjust = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ["set zonepath=#{opts[:zonepath]}"]})
          ssh ? adjust.exec_ssh(ssh) : adjust.exec
          logger.info("DEPLOY (#{opts[:id]}) -      Zonepath of zone #{zone_name} adjusted.")
        end
        logger.info("DEPLOY (#{opts[:id]}) -      Installing zone #{zone_name} from UAR...")
        logger.info("DEPLOY (#{opts[:id]}) -                uar: #{path_to_uar}...")
        cleaner.add_persistent_zone_installation(zone_name, host_spec)
        attach = SZONESBasicZoneCommands.attach_zone(zone_name, {:path_to_archive => path_to_uar} )
        ssh ? attach.exec_ssh(ssh) : attach.exec
        logger.info("DEPLOY (#{opts[:id]}) -      Installation of zone #{zone_name} finished.")
      end

      def self.deploy_zone_from_zfs_archive(zone_name, path_to_archive, path_to_zonecfg, opts = {}, ssh = nil, host_spec = {:host_name => 'localhost'})
        cleaner = opts[:cleaner]
        logger  = opts[:logger] || SZMGMT.logger
        logger.info("DEPLOY (#{opts[:id]}) -      Configuring zone #{zone_name} from command file...")
        logger.info("DEPLOY (#{opts[:id]}) -            zonecfg: #{path_to_zonecfg}...")
        configure = SZONESBasicZoneCommands.configure_zone_from_file(zone_name, path_to_zonecfg)
        ssh ? configure.exec_ssh(ssh) : configure.exec
        cleaner.add_persistent_zone_configuration(zone_name, host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Configuration of zone #{zone_name} created.")
        # Testing zonepath
        zonecfg = SZONESBasicZoneCommands.configure_zone(zone_name, { :commands => ['info zonepath'] })
        ssh ? zonecfg.exec_ssh(ssh) : zonecfg.exec
        # Parse output of zonecfg command in step 1) that should
        # return zonepath in format 'zonepath: /system/zones/Test\n'
        zonepath = zonecfg.stdout.chomp("\n").split(' ').last
        if zonepath.split('/').last != zone_name
          tokens = zonepath.split('/')
          tokens[-1] = zone_name
          opts[:zonepath] = tokens.join('/') unless opts[:zonepath]
        end

        if opts[:zonepath]
          logger.info("DEPLOY (#{opts[:id]}) -      Adjusting the zonepath of zone #{zone_name}...")
          adjust = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ["set zonepath=#{opts[:zonepath]}"]})
          ssh ? adjust.exec_ssh(ssh) : adjust.exec
          logger.info("DEPLOY (#{opts[:id]}) -      Zonepath of zone #{zone_name} adjusted.")
        end
        logger.info("DEPLOY (#{opts[:id]}) -      Installing zone #{zone_name} from ZFS archive...")
        logger.info("DEPLOY (#{opts[:id]}) -            archive: #{path_to_archive}...")
        cleaner.add_persistent_zone_installation(zone_name, host_spec)
        attach = SZONESBasicZoneCommands.attach_zone(zone_name, {:path_to_archive => path_to_archive} )
        ssh ? attach.exec_ssh(ssh) : attach.exec
        logger.info("DEPLOY (#{opts[:id]}) -      Installation of zone #{zone_name} finished.")
      end

      def self.deploy_zone_from_zfs_backup(zone_name, path_to_backup, opts = {}, ssh = nil, host_spec = {:host_name => 'localhost'})
        cleaner = opts[:cleaner]
        logger  = opts[:logger] || SZMGMT.logger
        logger.info("DEPLOY (#{opts[:id]}) -      Extracting ZFS backup...")
        unzip = SZONESBasicCommands.unzip_archive(path_to_backup)
        ssh ? unzip.exec_ssh(ssh) : unzip.exec
        base_name = path_to_backup.split('/').last.split('.').first
        path_to_archive = "#{base_name}.zfs.gz"
        cleaner.add_tmp_file(path_to_archive, host_spec)
        path_to_zonecfg= "#{base_name}.zonecfg"
        cleaner.add_tmp_file(path_to_zonecfg, host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Configuring zone #{zone_name} from command file...")
        logger.info("DEPLOY (#{opts[:id]}) -            zonecfg: #{path_to_zonecfg}...")
        configure = SZONESBasicZoneCommands.configure_zone_from_file(zone_name, path_to_zonecfg)
        ssh ? configure.exec_ssh(ssh) : configure.exec
        cleaner.add_persistent_zone_configuration(zone_name, host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Configuration of zone #{zone_name} created.")
        # Testing zonepath
        zonecfg = SZONESBasicZoneCommands.configure_zone(zone_name, { :commands => ['info zonepath'] })
        ssh ? zonecfg.exec_ssh(ssh) : zonecfg.exec
        # Parse output of zonecfg command in step 1) that should
        # return zonepath in format 'zonepath: /system/zones/Test\n'
        zonepath = zonecfg.stdout.chomp("\n").split(' ').last
        if zonepath.split('/').last != zone_name
          tokens = zonepath.split('/')
          tokens[-1] = zone_name
          opts[:zonepath] = tokens.join('/') unless opts[:zonepath]
        end

        if opts[:zonepath]
          logger.info("DEPLOY (#{opts[:id]}) -      Adjusting the zonepath of zone #{zone_name}...")
          adjust = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ["set zonepath=#{opts[:zonepath]}"]})
          ssh ? adjust.exec_ssh(ssh) : adjust.exec
          logger.info("DEPLOY (#{opts[:id]}) -      Zonepath of zone #{zone_name} adjusted.")
        end
        logger.info("DEPLOY (#{opts[:id]}) -      Installing zone #{zone_name} from ZFS archive...")
        logger.info("DEPLOY (#{opts[:id]}) -            archive: #{path_to_archive}...")
        cleaner.add_persistent_zone_installation(zone_name, host_spec)
        attach = SZONESBasicZoneCommands.install_zone(zone_name, {:path_to_archive => path_to_archive, :update => true} )
        ssh ? attach.exec_ssh(ssh) : attach.exec
        logger.info("DEPLOY (#{opts[:id]}) -      Installation of zone #{zone_name} finished.")
      end

      def self.boot_zone(zone_name, opts = {}, ssh = nil)
        logger  = opts[:logger] || SZMGMT.logger
        logger.info("DEPLOY (#{opts[:id]}) -      Booting up the zone #{zone_name}")
        boot = SZONESBasicZoneCommands.boot_zone(zone_name)
        ssh ? boot.exec_ssh(ssh) : boot.exec
        logger.info("DEPLOY (#{opts[:id]}) -      Zone #{zone_name} booted.")
      end

      def self.export_zone_to_zfs_archive(zone_name, opts = {}, ssh = nil, remote_host_spec = {:host_name => 'localhost'})
        tmp_dir             = opts[:tmp_dir] || '/var/tmp/'
        random_id           = SZONESUtils.random_id          # Used for storing files during this transaction
        base_name           = "#{zone_name}_#{random_id}"    # Used for storing files during this transaction
        snapshot_name       = base_name
        path_to_archive     = File.join(tmp_dir, "#{base_name}.zfs.gz")
        path_to_zonecfg     = File.join(tmp_dir, "#{base_name}.zonecfg")
        logger              = opts[:logger] || SZMGMT.logger

        cleaner = opts[:cleaner]
        logger.info("DEPLOY (#{opts[:id]}) -      Determinig volume name of zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
        volume = SZONESBasicRoutines.determine_zone_volume(zone_name, ssh)
        logger.info("DEPLOY (#{opts[:id]}) -      Creating snapshot of #{zone_name} on host #{remote_host_spec[:host_name]}...")
        snapshot = SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true })
        ssh ? snapshot.exec_ssh(ssh) : snapshot.exec
        cleaner.add_tmp_volume("#{volume}@#{snapshot_name}", remote_host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Creating archive of zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
        archive = SZONESBasicZFSCommands.archive_dataset("#{volume}@#{snapshot_name}", path_to_archive, { :recursive => true, :complete => true})
        ssh ? archive.exec_ssh(ssh) : archive.exec
        cleaner.add_tmp_file(path_to_archive, remote_host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Exporting zone #{zone_name} configuration on host #{remote_host_spec[:host_name]}...")
        zonecfg = SZONESBasicZoneCommands.export_zone_to_file(zone_name, path_to_zonecfg)
        ssh ? zonecfg.exec_ssh(ssh) : zonecfg.exec
        cleaner.add_tmp_file(path_to_zonecfg, remote_host_spec)
        [path_to_archive, path_to_zonecfg]
      end

      def self.export_zone_to_remote_zfs_archive(zone_name, destination_host_spec, opts = {}, ssh = nil, remote_host_spec = {:host_name => 'localhost'})
        tmp_dir             = opts[:tmp_dir] || '/var/tmp/'
        random_id           = SZONESUtils.random_id          # Used for storing files during this transaction
        base_name           = "#{zone_name}_#{random_id}"    # Used for storing files during this transaction
        snapshot_name       = base_name
        path_to_archive     = File.join(tmp_dir, "#{base_name}.zfs.gz")
        path_to_zonecfg     = File.join(tmp_dir, "#{base_name}.zonecfg")
        logger              = opts[:logger] || SZMGMT.logger
        cleaner = opts[:cleaner]
        logger.info("DEPLOY (#{opts[:id]}) -      Determinig volume name of zone #{zone_name} on host #{remote_host_spec[:host_name]}...")
        volume = SZONESBasicRoutines.determine_zone_volume(zone_name, ssh)
        logger.info("DEPLOY (#{opts[:id]}) -      Creating snapshot of #{zone_name} on host #{remote_host_spec[:host_name]}...")
        snapshot = SZONESBasicZFSCommands.create_snapshot(volume, snapshot_name, { :recursive => true })
        ssh ? snapshot.exec_ssh(ssh) : snapshot.exec
        cleaner.add_tmp_volume("#{volume}@#{snapshot_name}", remote_host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Creating archive of zone #{zone_name} on host #{destination_host_spec[:host_name]}:#{path_to_archive}...")
        archive = SZONESBasicZFSCommands.archive_dataset_on_remote("#{volume}@#{snapshot_name}", path_to_archive, destination_host_spec[:host_name],
                                                                   { :recursive => true, :complete => true})
        ssh ? archive.exec_ssh(ssh) : archive.exec
        cleaner.add_tmp_file(path_to_archive, destination_host_spec)
        logger.info("DEPLOY (#{opts[:id]}) -      Exporting zone #{zone_name} configuration on host #{destination_host_spec[:host_name]}:#{path_to_zonecfg}...")
        zonecfg = SZONESBasicZoneCommands.export_zone_to_remote_file(zone_name, path_to_zonecfg, destination_host_spec[:host_name])
        ssh ? zonecfg.exec_ssh(ssh) : zonecfg.exec
        cleaner.add_tmp_file(path_to_zonecfg, destination_host_spec)
        [path_to_archive, path_to_zonecfg]
      end
    end
  end
end