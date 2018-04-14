module SZMGMT
  module SZONES
    class SZONESBasicZoneCommands
      # ZONECFG ROUTINES
      def self.configure_zone_from_file(zone_name, path_to_command_file, opts = {})
        live_config = opts[:live_config] ? '-r' : ''
        Command.new("/usr/sbin/zonecfg -z #{zone_name} #{live_config} -f #{path_to_command_file}",
                    SZONESErrorHandlers.zonecfg_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end

      def self.configure_zone(zone_name, opts = {})
        live_config = opts[:live_config] ? '-r' : ''
        commands = opts[:commands] || []
        if commands.is_a? Array
          command = "'#{commands.join(";")}'"
        end
        Command.new("/usr/sbin/zonecfg -z #{zone_name} #{live_config} #{command}",
                    SZONESErrorHandlers.zonecfg_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Takes zone configuration and export it to file on
      # remote host. You can specify path where the file should
      # be stored
      def self.export_zone_to_file(zone_name, path_to_file)
        Command.new("/usr/sbin/zonecfg -z #{zone_name} export > #{path_to_file}",
                    SZONESErrorHandlers.zonecfg_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Takes zone configuration and export it to file on
      # remote host. You can specify remote path where the file should
      # be stored and the hostname.
      def self.export_zone_to_remote_file(zone_name, remote_path_to_file, host_name)
        Command.new("/usr/sbin/zonecfg -z #{zone_name} export | ssh #{host_name} \"cat > #{remote_path_to_file}\"",
                    SZONESErrorHandlers.zonecfg_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end

      # ZONEADM ROUTINES
      # Routine for zone booting. It boot or activate zone that is
      # specified. You can specify boot options with wich zone should boot.
      def self.boot_zone(zone_name, *boot_opts)
        boot_str = boot_opts.join(' ')
        Command.new("/usr/sbin/zoneadm -z #{zone_name} boot -- #{boot_str unless boot_opts.empty?}",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Basic routine for halting Solaris zone
      def self.halt_zone(zone_name)
        Command.new("/usr/sbin/zoneadm -z #{zone_name} halt",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)

      end
      # Reboot/Restart routine. This routine reboot/restart the given zone.
      # It's equivalent of halt and boot squence.
      def self.reboot_zone(zone_name, *boot_opts)
        boot_str = boot_opts.join(' ')
        Command.new("/usr/sbin/zoneadm -z #{zone_name} reboot -- #{boot_str unless boot_opts.empty?}",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Cleanly  shut down the zone (equivalent to running /usr/sbin/init 0
      # in the zone). The shutdown subcommand waits until the zone is  suc-
      # cessfully  shut  down;
      def self.shutdown_zone(zone_name)
        Command.new("/usr/sbin/zoneadm -z #{zone_name} shutdown",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end

      # Install the specified zone. Zone have to be in configured state to be
      # able to install. You can specify multiple files to controll the installation
      # process.
      def self.install_zone(zone_name, opts = {})
        manifest = opts[:path_to_manifest] ?  "-m #{opts[:path_to_manifest]}" : ''
        profile = opts[:path_to_profile] ? "-c #{opts[:path_to_profile]}" : ''
        archive = opts[:path_to_archive] ? "-a #{opts[:path_to_archive]}" : ''
        Command.new("/usr/sbin/zoneadm -z #{zone_name} install #{manifest} #{profile} #{archive}",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)

      end

      # Alternative way of installing zones (significantly faster). It clone source_zone
      # dataset thanks to ZFS and provide it as image to freshly created zone. You can
      # specify system profile to configure the create zone. Alternatively you can force
      # zfs to create a copy of filesystem not a clone.
      def self.clone_zone(zone_name, source_zone, opts = {})
        profile = opts[:path_to_profile] ? "-c #{opts[:path_to_profile]}" : ''
        Command.new("/usr/sbin/zoneadm -z #{zone_name} clone #{"-m copy" if opts[:copy]} #{profile} #{source_zone}",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end

      # Uninstall the specified zone from the system. Use this subcommand
      # with caution. It removes all of the files under the zonepath of the
      # zone in question.
      def self.uninstall_zone(zone_name, opts = {})
        force = opts[:force] || true
        Command.new("/usr/sbin/zoneadm -z #{zone_name} uninstall #{"-F" if force}",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end

      # Attaching zone means joining zone configuration with zone image. This
      # can happen in many ways. You can manually install the image on the path
      # specified in zonepath property or you can give an archive path from witch
      # the dataset should be retrieved. Archive can be in UAR or ZFS archive format.
      # Upon attaching the zone to system it can be updated if you specify the update
      # option or you can force command to attach with force option.
      def self.attach_zone(zone_name, opts = {})
        force = opts[:force] || false
        update = opts[:update] || false
        archive = opts[:path_to_archive] ? "-a #{opts[:path_to_archive]}" : ''
        Command.new("/usr/sbin/zoneadm -z #{zone_name} attach #{"-u" if update} #{"-F" if force} #{archive}",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end

      # Detaching means unplug zone configuration from its image. It change state of zone
      # from installed to configured. After detaching process is completed you can
      # archive the image and move it on other system where you can attach it again.
      def self.detach_zone(zone_name, opts = {})
        force = opts[:force] || false
        Command.new("/usr/sbin/zoneadm -z #{zone_name} detach #{"-F" if force}",
                    SZONESErrorHandlers.zoneadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end

      # Create unified archive from zones specified. Zones can be multiple zones
      # but only in case that option recovery is not specified. Exclude option
      # exclude BE for kernel zones and recovery option add all necessary manifests etc.
      # to recover zone from archive.
      def self.create_unified_archive(zone_names, path_to_archive,opts = {})
        exclude = opts[:exclude] || false
        recovery = opts[:recovery] || false
        if zone_names.is_a? Array
          zones = zone_names.join(',')
        else
          zones = zone_names
        end
        Command.new("/usr/sbin/archiveadm create -z #{zones} #{"-r" if recovery} #{"-e" if exclude} #{path_to_archive}",
                    SZONESErrorHandlers.archiveadm_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
    end
  end
end