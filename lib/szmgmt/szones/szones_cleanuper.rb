module SZMGMT
  module SZONES
    class SZONESCleanuper
      def initialize
        @tmp_files_by_hosts = Hash.new { |h, k| h[k] = [] }
        @tmp_volumes_by_hosts = Hash.new { |h, k| h[k] = [] }

        @per_volumes_by_hosts = Hash.new { |h, k| h[k] = [] }
        @per_zonecfg_by_hosts = Hash.new { |h, k| h[k] = [] }
        @per_install_by_hosts = Hash.new { |h, k| h[k] = [] }
        @hosts_specs = {}
      end
      # Add temporary file that will be deleted in every case
      # this file is not important for result of transaction
      def add_tmp_file(path_to_file, host_spec = {:host_name => 'localhost'})
        @tmp_files_by_hosts[host_spec[:host_name]] << path_to_file
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      # Add temporary volume as snapshot that will be deleted in every case
      # this volume is not important for result of transaction it is only
      # needed in it's progression.
      def add_tmp_volume(volume, host_spec = {:host_name => 'localhost'})
        @tmp_volumes_by_hosts[host_spec[:host_name]] << volume
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end
      # Add persistent volume  that will be deleted only if transaction failed.
      # this volume is  important for result of transaction and it is
      # needed after it ends.
      def add_persistent_volume(volume, host_spec = {:host_name => 'localhost'})
        @per_volumes_by_hosts[host_spec[:host_name]] << volume
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end
      # Add persistent zone configuration that will be deleted only if transaction failed.
      # this configuration is  important for result of transaction and it is
      # needed after it ends.
      def add_persistent_zone_configuration(zone_name, host_spec = {:host_name => 'localhost'})
        @per_zonecfg_by_hosts[host_spec[:host_name]] << zone_name
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def add_persistent_zone_installation(zone_name, host_spec = {:host_name => 'localhost'})
        @per_install_by_hosts[host_spec[:host_name]] << zone_name
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def cleanup_temporary!
        SZMGMT.logger.info("CLEANUP: Initializing cleanup of temporary files...")
        Parallel.each(@hosts_specs.keys, in_processes: @hosts_specs.keys.size ) do |host|
          SZMGMT.logger.info("CLEANUP: Cleanup of temporary resources on host #{host} has been initialized.")
          if host == 'localhost'
            cleanup_temporary_routine(host)
          else
            host_spec = @hosts_specs[host]
            Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
              cleanup_temporary_routine(host, ssh)
            end
          end
        end
        SZMGMT.logger.info("CLEANUP: Cleanup of temporary resources finished.")
      end

      def cleanup_on_failure!
        SZMGMT.logger.info("CLEANUP: Initializing cleanup of persistent files (transaction failed)...")
        Parallel.each(@hosts_specs.keys, in_processes: @hosts_specs.keys.size ) do |host|
          SZMGMT.logger.info("CLEANUP: Cleanup of persistent resources on host #{host} has been initialized.")
          if host == 'localhost'
            cleanup_persistent_routine(host)
          else
            host_spec = @hosts_specs[host]
            Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
              cleanup_persistent_routine(host, ssh)
            end
          end
        end
        SZMGMT.logger.info("CLEANUP: Cleanup of persistent resources finished.")
      end

      private

      def cleanup_temporary_routine(host, ssh = nil)
        @tmp_files_by_hosts[host].each do |path_to_file|
          SZMGMT.logger.info("CLEANUP: Removing file '#{path_to_file}' from host '#{host}'.")
          begin
            rm = SZONESBasicCommands.remove_file(path_to_file)
            ssh ? rm.exec_ssh(ssh) : rm.exec
          rescue Exceptions::SZONESError
            SZMGMT.logger.warn("CLEANUP: Cannot remove file '#{path_to_file}' from host '#{host}'.")
          end
        end
        @tmp_volumes_by_hosts[host].each do |volume_name|
          SZMGMT.logger.info("CLEANUP: Removing temporary volume '#{volume_name}' from host '#{host}'.")
          begin
            destroy = SZONESBasicZFSCommands.destroy_dataset(volume_name, {:recursive => true})
            ssh ? destroy.exec_ssh(ssh) : destroy.exec
          rescue Exceptions::SZONESError
            SZMGMT.logger.warn("CLEANUP: Cannot remove temporary volume '#{volume_name}' from host '#{host}'.")
          end
        end
      end

      def cleanup_persistent_routine(host, ssh = nil)
        @per_install_by_hosts[host].each do |zone_name|
          SZMGMT.logger.info("CLEANUP: Removing zone installation '#{zone_name}' from host '#{host}'.")
          begin
            uninstall = SZONESBasicZoneCommands.uninstall_zone(zone_name, {:commands => ['delete -F']})
            ssh ? uninstall.exec_ssh(ssh) : uninstall.exec
          rescue Exceptions::SZONESError
            SZMGMT.logger.warn("CLEANUP: Cannot remove zone installation '#{zone_name}' from host '#{host}'.")
          end
        end
        @per_volumes_by_hosts[host].each do |volume_name|
          SZMGMT.logger.info("CLEANUP: Removing persistent volume '#{volume_name}' from host '#{host}'.")
          begin
            destroy = SZONESBasicZFSCommands.destroy_dataset(volume_name, {:recursive => true})
            ssh ? destroy.exec_ssh(ssh) : destroy.exec
          rescue Exceptions::SZONESError
            SZMGMT.logger.warn("CLEANUP: Cannot remove persistent volume '#{volume_name}' from host '#{host}'.")
          end
        end
        @per_zonecfg_by_hosts[host].each do |zone_name|
          SZMGMT.logger.info("CLEANUP: Removing zone configuration '#{zone_name}' from host '#{host}'.")
          begin
            delete = SZONESBasicZoneCommands.configure_zone(zone_name, {:commands => ['delete -F']})
            ssh ? delete.exec_ssh(ssh) : delete.exec
          rescue Exceptions::SZONESError
            SZMGMT.logger.warn("CLEANUP: Cannot remove zone configuration '#{zone_name}' from host '#{host}'.")
          end
        end
      end
    end
  end
end