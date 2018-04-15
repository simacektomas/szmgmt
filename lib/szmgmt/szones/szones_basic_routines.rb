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
    end
  end
end
