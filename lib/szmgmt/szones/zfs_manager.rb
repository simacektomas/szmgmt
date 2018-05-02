module SZMGMT
  module SZONES
    class ZFSDatasetManager
      def self.dataset_exist?(zfs_dataset)
        check = SZONES::Command.new("/usr/sbin/zfs list #{zfs_dataset}")
        begin
          check.exec
        rescue SZONES::Exceptions::CommandFailureError
          return false
        end
        true
      end

      def self.remote_dataset_exists?(zfs_dataset, host_spec)
        executor = SZONES::CommandExecutor.new
        check = SZONES::Command.new("/usr/sbin/zfs list #{zfs_dataset}")
        executor.add_command(check)
        begin
          executor.remote_ssh_execute(host_spec)
        rescue SZONES::Exceptions::CommandFailureError
          return false
        end
        true
      end

      def self.create_dataset(zfs_dataset)
        create = SZONES::Command.new("/usr/sbin/zfs create #{zfs_dataset}")
        begin
          create.exec
        rescue SZONES::Exceptions::CommandFailureError
          return false
        end
        true
      end

      def self.create_remote_dataset(zfs_dataset, host_spec)
        executor = SZONES::CommandExecutor.new
        create = SZONES::Command.new("/usr/sbin/zfs create #{zfs_dataset}")
        executor.add_command(create)
        begin
          executor.remote_ssh_execute(host_spec)
        rescue SZONES::Exceptions::CommandFailureError
          return false
        end
        true
      end

      def self.dataset_mountpoint(zfs_dataset)
        query = SZONES::Command.new("/usr/sbin/zfs list -H -o mountpoint #{zfs_dataset}")
        begin
          query.exec
        rescue SZONES::Exceptions::CommandFailureError
          return nil
        end
        query.stdout.chomp("\n")
      end

      def self.remote_dataset_mountpoint(zfs_dataset, host_spec)
        executor = SZONES::CommandExecutor.new
        query = SZONES::Command.new("/usr/sbin/zfs list -H -o mountpoint #{zfs_dataset}")
        executor.add_command(query)
        begin
          executor.remote_ssh_execute(host_spec)
        rescue SZONES::Exceptions::CommandFailureError
          return nil
        end
        query.stdout.chomp("\n")
      end
    end
  end
end