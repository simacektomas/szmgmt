module SZMGMT
  module SZONES
    class SZONESBasicRoutines
      # Determine where the image of zone is stored. From zone name
      # we can determine zonepath property and then we can find tho volume
      # Steps:
      #   1) zonecfg -z %{zone_name} info zonepath    - Determine zone image mountpoint.
      #   2) zfs list -H -o name %{zonepath}          - Determine zone volume.
      def self.determine_zone_volume(zone_name, ssh = nil)
        # Assemble command in step 1 to deretmine where the
        # zone is mounted.
        zonecfg = SZONESBasicZoneCommands.configure_zone(zone_name, { :commands => ['info zonepath'] })
        ssh ? zonecfg.exec_ssh(ssh) : zonecfg.exec
        # Parse output of zonecfg command in step 1) that should
        # return zonepath in format 'zonepath: /system/zones/Test\n'
        zonepath = zonecfg.stdout.chomp("\n").split(' ').last
        # Assemble command in step 2 to determine volume of
        # the zone
        zfs_list = SZONESBasicZFSCommands.list_properties(zonepath, ['name'], { :header => true })
        ssh ? zfs_list.exec_ssh(ssh) : zfs_list.exec
        # Parse output of zfs list in step 2) that should
        # return dataset in format 'rpool/VARSHARE/zones/zdevel\n'
        zfs_list.stdout.chomp("\n")
      end
      # Determine the mountpoint of given ZFS volume
      # Steps:
      #   1) zfs list -H -o name %{zonepath}          - Determine volume mountpoint.
      def self.determine_volume_mountpoint(volume, ssh = nil)
        zfs_list = SZONESBasicZFSCommands.list_properties(volume, ['mountpoint'], { :header => true })
        ssh ? zfs_list.exec_ssh(ssh) : zfs_list.exec
        # Parse output of zfs list in step 2) that should
        # return dataset in format 'rpool/VARSHARE/zones/zdevel\n'
        zfs_list.stdout.chomp("\n")
      end

      def self.list_zones(host_spec = {:host_name => 'localhost'})
        list = SZONESBasicZoneCommands.list_zones({:installed => true, :configured => true, :parse => true})
        if host_spec[:host_name] == 'localhost'
          SZMGMT.logger.info("LIST - Listing zones on localhost.")
          list.exec
        else
          SZMGMT.logger.info("LIST - Connection to #{host_spec[:host_name]} to list zones.")
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec.to_h) do |ssh|
            list.exec_ssh(ssh)
          end
        end
        zones = []
        #Parse output
        list.stdout.each_line do |zone|
          zone_hash = {}
          properties = zone.split(':')
          #zone_hash[:id] = properties[0]
          zone_hash[:name] = properties[1]
          zone_hash[:state] = properties[2]
          zone_hash[:zonepath] = properties[3]
          #zone_hash[:uid] = properties[4]
          zone_hash[:brand] = properties[5]
          zone_hash[:ip] = properties[6]
          zones << zone_hash
        end
        zones
      end

      def self.boot_zone(zone_name, host_spec = {:host_name => 'localhost'}, *boot_opts)
        boot_zone = SZONESBasicZoneCommands.boot_zone(zone_name, boot_opts)
        if host_spec[:host_name] == 'localhost'
          SZMGMT.logger.info("BOOT - Boot of zone #{zone_name}:localhost initiated.")
          boot_zone.exec
          SZMGMT.logger.info("BOOT - Zone #{zone_name}:localhost boot finished.")
        else
          SZMGMT.logger.info("BOOT - Connecting to #{host_spec[:host_name]}.")
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec.to_h) do |ssh|
            SZMGMT.logger.info("BOOT - Boot of zone #{zone_name}:#{host_spec[:host_name]} initiated.")
            boot_zone.exec_ssh(ssh)
            SZMGMT.logger.info("BOOT - Zone #{zone_name}:#{host_spec[:host_name]} boot finished.")
          end
        end
      end

      def self.shutdown_zone(zone_name, host_spec = {:host_name => 'localhost'})
        shutdown_zone = SZONESBasicZoneCommands.shutdown_zone(zone_name)
        if host_spec[:host_name] == 'localhost'
          SZMGMT.logger.info("SHUTDOWN - Shutdown zone #{zone_name}:localhost initiated.")
          shutdown_zone.exec
          SZMGMT.logger.info("SHUTDOWN - Zone #{zone_name}:localhost shutdown finished.")
        else
          SZMGMT.logger.info("SHUTDOWN - Connecting to #{host_spec[:host_name]}.")
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec.to_h) do |ssh|
            SZMGMT.logger.info("SHUTDOWN - Shutdown zone #{zone_name}:#{host_spec[:host_name]} initiated.")
            shutdown_zone.exec_ssh(ssh)
            SZMGMT.logger.info("SHUTDOWN - Zone #{zone_name}:#{host_spec[:host_name]} shutdown finished.")
          end
        end
      end

      def self.halt_zone(zone_name, host_spec = {:host_name => 'localhost'})
        halt_zone = SZONESBasicZoneCommands.halt_zone(zone_name)
        if host_spec[:host_name] == 'localhost'
          SZMGMT.logger.info("HALT - Halt of zone #{zone_name}:localhost initiated.")
          halt_zone.exec
          SZMGMT.logger.info("HALT - Zone #{zone_name}:localhost halt finished.")
        else
          SZMGMT.logger.info("HALT - Connecting to #{host_spec[:host_name]}.")
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec.to_h) do |ssh|
            SZMGMT.logger.info("HALT - Halt of zone #{zone_name}:#{host_spec[:host_name]} initiated.")
            halt_zone.exec_ssh(ssh)
            SZMGMT.logger.info("HALT - Zone #{zone_name}:#{host_spec[:host_name]} halt finished.")
          end
        end
      end

      def self.reboot_zone(zone_name, host_spec = {:host_name => 'localhost'}, *boot_opts)
        reboot_zone = SZONESBasicZoneCommands.reboot_zone(zone_name, boot_opts)
        if host_spec[:host_name] == 'localhost'
          SZMGMT.logger.info("REBOOT - Reboot of zone #{zone_name}:localhost initiated.")
          reboot_zone.exec
          SZMGMT.logger.info("REBOOT - Zone #{zone_name}:localhost reboot finished.")
        else
          SZMGMT.logger.info("REBOOT - Connecting to #{host_spec[:host_name]}.")
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec.to_h) do |ssh|
            SZMGMT.logger.info("REBOOT - Reboot of zone #{zone_name}:#{host_spec[:host_name]} initiated.")
            reboot_zone.exec_ssh(ssh)
            SZMGMT.logger.info("REBOOT - Zone #{zone_name}:#{host_spec[:host_name]} reboot finished.")
          end
        end
      end

      def self.uninstall_zone(zone_name, host_spec = {:host_name => 'localhost'})
        uninstall_zone = SZONESBasicZoneCommands.uninstall_zone(zone_name)
        if host_spec[:host_name] == 'localhost'
          SZMGMT.logger.info("UNINSTALL - Uninstall of zone #{zone_name}:localhost initiated.")
          uninstall_zone.exec
          SZMGMT.logger.info("UNINSTALL - Zone #{zone_name}:localhost uninstall finished.")
        else
          SZMGMT.logger.info("UNINSTALL - Connecting to #{host_spec[:host_name]}.")
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec.to_h) do |ssh|
            SZMGMT.logger.info("UNINSTALL - Uninstall of zone #{zone_name}:#{host_spec[:host_name]} initiated.")
            uninstall_zone.exec_ssh(ssh)
            SZMGMT.logger.info("UNINSTALL - Zone #{zone_name}:#{host_spec[:host_name]} uninstall finished.")
          end
        end
      end

      def self.unconfigure_zone(zone_name, host_spec = {:host_name => 'localhost'})
        unconfigure_zone = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ['delete -F']})
        if host_spec[:host_name] == 'localhost'
          SZMGMT.logger.info("UNCONFIGURE - Unconfiguration of zone #{zone_name}:localhost initiated.")
          unconfigure_zone.exec
          SZMGMT.logger.info("UNCONFIGURE - Zone #{zone_name}:localhost unconfiguration finished.")
        else
          SZMGMT.logger.info("UNCONFIGURE - Connecting to #{host_spec[:host_name]}.")
          Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec.to_h) do |ssh|
            SZMGMT.logger.info("UNCONFIGURE - Unconfiguration of zone #{zone_name}:#{host_spec[:host_name]} initiated.")
            unconfigure_zone.exec_ssh(ssh)
            SZMGMT.logger.info("UNCONFIGURE - Zone #{zone_name}:#{host_spec[:host_name]} unconfiguration finished.")
          end
        end
      end
    end
  end
end
