module SZMGMT
  module SZONES
    class SZONESDeploymentSubroutines
      def self.deploy_zone_from_files(zone_name, path_to_zonecfg, opts = {}, ssh = nil, host_spec = {:host_name => 'localhost'})
        cleaner = opts[:cleaner]

        SZMGMT.logger.info("DEPLOY (#{opts[:id]}) -      Configuring zone #{zone_name}...")
        SZMGMT.logger.info("DEPLOY (#{opts[:id]}) -             config: #{path_to_zonecfg}")
        configure = SZONESBasicZoneCommands.configure_zone_from_file(zone_name, path_to_zonecfg)
        ssh ? configure.exec_ssh(ssh) : configure.exec
        cleaner.add_persistent_zone_configuration(zone_name, host_spec)
        SZMGMT.logger.info("DEPLOY (#{opts[:id]}) -      Installing zone #{zone_name}.")
        SZMGMT.logger.info("DEPLOY (#{opts[:id]}) -           manifest: #{opts[:path_to_manifest]}") if opts[:path_to_manifest]
        SZMGMT.logger.info("DEPLOY (#{opts[:id]}) -            profile: #{opts[:path_to_profile]}") if opts[:path_to_profile]
        cleaner.add_persistent_zone_installation(zone_name, host_spec)
        install = SZONESBasicZoneCommands.install_zone(zone_name, {:path_to_manifest => opts[:path_to_manifest],
                                                                   :path_to_profile => opts[:path_to_profile] })
        ssh ? install.exec_ssh(ssh) : install.exec
      end
    end
  end
end