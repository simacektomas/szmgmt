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
    end
  end
end
