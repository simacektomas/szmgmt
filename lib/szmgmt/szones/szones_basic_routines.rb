module SZMGMT
  module SZONES
    class SZONESBasicRoutines
      # Routine for zone booting. It boot or activate zone that is
      # specified. You can specify boot options with wich zone should boot.
      def self.boot_zone(zone_name, ssh = nil, *boot_opts)
        boot_str = boot_opts.join(' ')
        boot = Command.new("/usr/sbin/zoneadm -z #{zone_name} boot -- #{boot_str unless boot_opts.empty?}",
                           SZONESErrorHandlers.zoneadm_error_handler,
                           SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{boot.command}")
        ssh ? boot.exec_ssh(ssh) : boot.exec
      end
      # Basic routine for halting Solaris zone
      def self.halt_zone(zone_name, ssh = nil)
        halt = Command.new("/usr/sbin/zoneadm -z #{zone_name} halt",
                           SZONESErrorHandlers.zoneadm_error_handler,
                           SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{halt.command}")
        ssh ? halt.exec_ssh(ssh) : halt.exec
      end
      # Reboot/Restart routine. This routine reboot/restart the given zone.
      # It's equivalent of halt and boot squence.
      def self.reboot_zone(zone_name, ssh = nil, *boot_opts)
        boot_str = boot_opts.join(' ')
        reboot = Command.new("/usr/sbin/zoneadm -z #{zone_name} reboot -- #{boot_str unless boot_opts.empty?}",
                             SZONESErrorHandlers.zoneadm_error_handler,
                             SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{reboot.command}")
        ssh ? reboot.exec_ssh(ssh) : reboot.exec
      end
      # Cleanly  shut down the zone (equivalent to running /usr/sbin/init 0
      # in the zone). The shutdown subcommand waits until the zone is  suc-
      # cessfully  shut  down;
      def self.shutdown_zone(zone_name, ssh = nil)
        shutdown = Command.new("/usr/sbin/zoneadm -z #{zone_name} shutdown",
                               SZONESErrorHandlers.zoneadm_error_handler,
                               SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{shutdown.command}")
        ssh ? shutdown.exec_ssh(ssh) : shutdown.exec
      end

      # Install the specified zone. Zone have to be in configured state to be
      # able to install. You can specify multiple files to controll the installation
      # process.
      def self.install_zone(zone_name, ssh = nil, opts = {})
        manifest = opts[:path_to_manifest] ?  "-m #{opts[:path_to_manifest]}" : ''
        profile = opts[:path_to_profile] ? "-c #{opts[:path_to_profile]}" : ''
        archive = opts[:path_to_archive] ? "-a #{opts[:path_to_archive]}" : ''
        install = Command.new("/usr/sbin/zoneadm -z #{zone_name} install #{manifest} #{profile} #{archive}",
                              SZONESErrorHandlers.zoneadm_error_handler,
                              SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{install.command}")
        ssh ? install.exec_ssh(ssh) : install.exec
      end

      # Alternative way of installing zones (significantly faster). It clone source_zone
      # dataset thanks to ZFS and provide it as image to freshly created zone. You can
      # specify system profile to configure the create zone. Alternatively you can force
      # zfs to create a copy of filesystem not a clone.
      def self.clone_zone(zone_name, source_zone, ssh = nil, opts = {})
        profile = opts[:path_to_profile] ? "-c #{opts[:path_to_profile]}" : ''
        clone = Command.new("/usr/sbin/zoneadm -z #{zone_name} clone #{"-m copy" if opts[:copy]} #{profile} #{source_zone}",
                              SZONESErrorHandlers.zoneadm_error_handler,
                              SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{clone.command}")
        ssh ? clone.exec_ssh(ssh) : clone.exec
      end

      # Uninstall the specified zone from the system. Use this subcommand
      # with caution. It removes all of the files under the zonepath of the
      # zone in question.
      def self.uninstall_zone(zone_name, ssh = nil, opts = {})
        force = opts[:force] || true
        uninstall = Command.new("/usr/sbin/zoneadm -z #{zone_name} uninstall #{"-F" if force}",
                                SZONESErrorHandlers.zoneadm_error_handler,
                                SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{uninstall.command}")
        ssh ? uninstall.exec_ssh(ssh) : uninstall.exec
      end

      # Attaching zone means joining zone configuration with zone image. This
      # can happen in many ways. You can manually install the image on the path
      # specified in zonepath property or you can give an archive path from witch
      # the dataset should be retrieved. Archive can be in UAR or ZFS archive format.
      # Upon attaching the zone to system it can be updated if you specify the update
      # option or you can force command to attach with force option.
      def self.attach_zone(zone_name, ssh = nil, opts = {})
        force = opts[:force] || false
        update = opts[:update] || false
        archive = opts[:path_to_archive] ? "-a #{opts[:path_to_archive]}" : ''
        attach = Command.new("/usr/sbin/zoneadm -z #{zone_name} attach #{"-u" if update} #{"-F" if force} #{archive}",
                             SZONESErrorHandlers.zoneadm_error_handler,
                             SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{attach.command}")
        ssh ? attach.exec_ssh(ssh) : attach.exec
      end

      # Detaching means unplug zone configuration from its image. It change state of zone
      # from installed to configured. After detaching process is completed you can
      # archive the image and move it on other system where you can attach it again.
      def self.detach_zone(zone_name, ssh = nil, opts = {})
        force = opts[:force] || false
        detach = Command.new("/usr/sbin/zoneadm -z #{zone_name} detach #{"-F" if force}",
                             SZONESErrorHandlers.zoneadm_error_handler,
                             SZONESErrorHandlers.basic_error_handler)
        SZMGMT.logger.debug("Running - #{detach.command}")
        ssh ? detach.exec_ssh(ssh) : detach.exec
      end
    end
  end
end