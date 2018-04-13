module SZMGMT
  module SZONES
    class SZONESRoutines
      def self.backup_zone_uar(zonename, path_to_arhive, ssh = nil)
        # Create Unified archive with zone
        archive = Command.new("/usr/sbin/archiveadm create -z #{zonename} -e #{path_to_arhive}")
        ssh ? archive.exec_ssh(ssh) : archive.exec
      end

      def self.backup_zone_zfs_archive(zone_name, path_to_arhive, ssh = nil)
        # Create ZFS archive of specified zone
        # #
        zonecfg = Command.new("/usr/sbin/zonecfg -z #{zone_name} info zonepath", SZONESErrorHandlers.zonecfg_error_handler,
                                                                                 SZONESErrorHandlers.basic_error_handler )

        ssh ? zonecfg.exec_ssh(ssh) : zonecfg.exec
        zone_path = zonecfg.stdout.split(" ").last.chomp("\n")
        #
        zonepool = Command.new("/usr/sbin/zfs list -H -o name #{zone_path}", SZONESErrorHandlers.zfs_error_handler,
                                                                             SZONESErrorHandlers.basic_error_handler )
        ssh ? zonepool.exec_ssh(ssh) : zonepool.exec
        #
        snapshot_name = "#{zonepool.stdout.chomp("\n")}@#{zone_name}_archive_#{Time.now.to_i}"
        snapshot = Command.new("/usr/sbin/zfs snapshot -r #{snapshot_name}", SZONESErrorHandlers.zfs_error_handler,
                                                                             SZONESErrorHandlers.basic_error_handler )
        ssh ? snapshot.exec_ssh(ssh) : snapshot.exec
        #
        archive = Command.new("/usr/sbin/zfs send -rc #{snapshot_name} | gzip > #{path_to_arhive}", SZONESErrorHandlers.zfs_error_handler,
                                                                                                    SZONESErrorHandlers.bash_error_handler,
                                                                                                    SZONESErrorHandlers.basic_error_handler )
        ssh ? archive.exec_ssh(ssh) : archive.exec
      end
    end
  end
end