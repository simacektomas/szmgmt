module SZMGMT
  module SZONES
    class SZONESCleanuper
      def initialize
        @files_by_hosts =  Hash.new { |h, k| h[k] = [] }
        @volumes_by_hosts = Hash.new { |h, k| h[k] = [] }
        @hosts_specs = {}
      end
      # Add file that should be destroyed to specified host.
      def add_file(path_to_file, host_spec = {:host_name => 'localhost'})
        @files_by_hosts[host_spec[:host_name]] << path_to_file
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end
      # Add volume that should be destroyed to specified host.
      def add_volume(volume, host_spec = {:host_name => 'localhost'})
        @volumes_by_hosts[host_spec[:host_name]] << volume
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def cleanup!
        SZMGMT.logger.info("CLEANUP: Initializing cleanup...")
        Parallel.each(@hosts_specs.keys, in_processes: @hosts_specs.keys.size ) do |host|
          SZMGMT.logger.info("CLEANUP: Cleanup of resources on host #{host} has been initialized.")
          if host == 'localhost'
            @files_by_hosts[host].each do |path_to_file|
              SZMGMT.logger.info("CLEANUP: Removing file '#{path_to_file}' from host '#{host}'")
              SZONESBasicCommands.remove_file(path_to_file).exec
            end
            @volumes_by_hosts[host].each do |volume_name|
              SZMGMT.logger.info("CLEANUP: Removing volume '#{volume_name}' from host '#{host}'")
              SZONESBasicZFSCommands.destroy_dataset(volume_name, {:recursive => true}).exec
            end
          else
            host_spec = @hosts_specs[host]
            Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
              @files_by_hosts[host].each do |path_to_file|
                SZMGMT.logger.info("CLEANUP: Removing file '#{path_to_file}' from host '#{host}'")
                SZONESBasicCommands.remove_file(path_to_file).exec_ssh(ssh)
              end
              @volumes_by_hosts[host].each do |volume_name|
                SZMGMT.logger.info("CLEANUP: Removing volume '#{volume_name}' from host '#{host}'")
                SZONESBasicZFSCommands.destroy_dataset(volume_name, {:recursive => true}).exec_ssh(ssh)
              end
            end
          end
        end
      end
    end
  end
end