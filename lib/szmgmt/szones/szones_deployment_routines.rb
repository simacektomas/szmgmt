module SZMGMT
  module SZONES
    class SZONESDeploymentRoutines
      def self.decompose_vm_spec(vm_spec)
        parser = SZONESVMSpecParser.new(vm_spec)
        zonecfg   = parser.vm_spec_configuration
        manifest  = parser.vm_spec_manifest
        profile   = parser.vm_spec_profile
        [zonecfg, manifest, profile]
      end
      # Routine for deploying zone from configuration files. Frist file
      # is zone command file that can be exported from zonecfg command.
      # This file is the only one mandatory. Then you can specify manifest
      # and profile file that will be used with zone installation. If you
      # specify boot option the zone will boot after successful installation.
      # Steps:
      #   1) zonecfg -z %{zonename} -f %{path_to_zonecfg}   - Create zone configuration
      #   2) zoneadm -z %{zonename} install -m %{manifest}  - Install the zone using manifest and
      #                                     -c %{profile}     profile files
      #   if boot
      #   3) zoneadm -z %{zonename} boot                    - Boot the zone if boot opt specified
      def self.deploy_zone_from_files(zone_name, path_to_zonecfg, opts = {})
        ##########
        # OPTIONS
        boot                = opts[:boot] || false
        path_to_manifest    = opts[:path_to_manifest]
        path_to_profile     = opts[:path_to_profile]
        ##########
        # PREPARATION
        cleaner             = SZONESCleanuper.new
        id                  = SZONESUtils.transaction_id
        ##########
        # EXECUTION
        SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of zone #{zone_name} on localhost has been initialize...")
        SZMGMT.logger.info("DEPLOY (#{id}) -      type: FILES")
        begin
          SZONESDeploymentSubroutines.deploy_zone_from_files(zone_name,
                                                             path_to_zonecfg,
                                                             {
                                                                 :id => id,
                                                                 :path_to_profile => path_to_profile,
                                                                 :path_to_manifest => path_to_manifest,
                                                                 :cleaner => cleaner
                                                             })
        rescue  Exceptions::SZONESError
          SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of template #{zone_name} failed.")
          cleaner.cleanup_on_failure!
        else
          SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of template #{zone_name} succeeded.")
          if boot
            SZMGMT.logger.info("DEPLOY (#{id}) - Booting up zone #{zone_name}")
            SZONESBasicZoneCommands.boot_zone(zone_name).exec
            SZMGMT.logger.info("DEPLOY (#{id}) - Zone #{zone_name} booted.")
          end
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Routine for deploying TEMPLATE from configuration files. Frist file
      # is zone command file that can be exported from zonecfg command.
      # This file is the only one mandatory. Then you can specify manifest
      # and profile file that will be used with zone installation. If you
      # specify boot option the zone will boot after successful installation.
      # Only diference from previous routine is the name of zone.
      # Steps:
      #   1) zonecfg -z %{zonename} -f %{path_to_zonecfg}   - Create zone configuration
      #   2) zoneadm -z %{zonename} install -m %{manifest}  - Install the zone using manifest and
      #                                     -c %{profile}     profile files
      #   if boot
      #   3) zoneadm -z %{zonename} boot                    - Boot the zone if boot opt specified
      def self.deploy_template_from_files(template_name, path_to_zonecfg, opts = {})
        full_template_name = "template_#{template_name}"
        deploy_zone_from_files(full_template_name, path_to_zonecfg, opts)
      end
      # Routine for deploying zone from vm_spec. This object is composition
      # of all needed configuration files as zonecfg, manifest and profile. So
      # firstly we need to decompose the vm_spec to specified files. If you
      # specify boot option the zone will boot after successful installation.
      # Only diference from previous routine is the name of zone.
      # Steps:
      #   1) zonecfg -z %{zonename} -f %{path_to_zonecfg}   - Create zone configuration
      #   2) zoneadm -z %{zonename} install -m %{manifest}  - Install the zone using manifest and
      #                                     -c %{profile}     profile files
      #   if boot
      #   3) zoneadm -z %{zonename} boot                    - Boot the zone if boot opt specified
      def self.deploy_zone_from_vm_spec(zone_name, vm_spec, opts = {})
        ##########
        # OPTIONS
        boot                = opts[:boot] || false
        tmp_dir             = opts[:tmp_dir] || '/var/tmp/'
        ##########
        # PREPARATION
        cleaner             = SZONESCleanuper.new
        id                  = SZONESUtils.transaction_id     # Used for marking this transaction
        random_id           = SZONESUtils.random_id          # Used for storing files during this transaction
        base_name           = "#{zone_name}_#{random_id}"    # Used for storing files during this transaction
        # Prepare file from vm_spec. It means parse vm_spec and
        # export it's parts to temporary files to target machine
        zonecfg, manifest, profile = decompose_vm_spec(vm_spec)
        # Export zonecfg to file
        path_to_zonecfg = File.join(tmp_dir, "#{base_name}.zonecfg")
        zonecfg.export_configuration_to_file(path_to_zonecfg)
        cleaner.add_tmp_file(path_to_zonecfg)
        # Export manifest to file if it was in VM_SPEC
        if manifest
          path_to_manifest = File.join(tmp_dir, "#{base_name}.manifest.xml")
          manifest.export_manifest_to_file(path_to_manifest)
          cleaner.add_tmp_file(path_to_manifest)
        end
        # Export profile to file if it was in VM_SPEC
        if profile
          path_to_profile = File.join(tmp_dir, "#{base_name}.profile.xml")
          profile.export_profile_to_file(path_to_profile)
          cleaner.add_tmp_file(path_to_profile)
        end
        ##########
        # EXECUTION
        SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of zone #{zone_name} on localhost has been initialize...")
        SZMGMT.logger.info("DEPLOY (#{id}) -      type: VM_SPEC")
        SZMGMT.logger.info("DEPLOY (#{id}) -   vm_spec: #{vm_spec['name']}")
        begin
          SZONESDeploymentSubroutines.deploy_zone_from_files(zone_name,
                                                             path_to_zonecfg,
                                                             {
                                                                 :id => id,
                                                                 :path_to_profile => path_to_profile,
                                                                 :path_to_manifest => path_to_manifest,
                                                                 :cleaner => cleaner
                                                             })
        rescue  Exceptions::SZONESError
          SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of template #{zone_name} failed.")
          cleaner.cleanup_on_failure!
        else
          SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of zone #{zone_name} succeeded.")
          if boot
            SZMGMT.logger.info("DEPLOY (#{id}) - Booting up zone #{zone_name}...")
            SZONESBasicZoneCommands.boot_zone(zone_name).exec
            SZMGMT.logger.info("DEPLOY (#{id}) - Zone #{zone_name} booted.")
          end
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Routine for deploying TEMPLATE from vm_spec. This object is composition
      # of all needed configuration files as zonecfg, manifest and profile. So
      # firstly we need to decompose the vm_spec to specified files. If you
      # specify boot option the zone will boot after successful installation.
      # Only diference from previous routine is the name of zone.
      # Steps:
      #   1) zonecfg -z %{zonename} -f %{path_to_zonecfg}   - Create zone configuration
      #   2) zoneadm -z %{zonename} install -m %{manifest}  - Install the zone using manifest and
      #                                     -c %{profile}     profile files
      #   if boot
      #   3) zoneadm -z %{zonename} boot                    - Boot the zone if boot opt specified
      def self.deploy_template_from_vm_spec(template_name, vm_spec, opts = {})
        full_template_name = "template_#{template_name}"
        deploy_zone_from_vm_spec(full_template_name, vm_spec, opts)
      end
      # Routine for deploying zone from files on remote server. Frist file
      # is zone command file that can be exported from zonecfg command.
      # This file is the only one mandatory. Then you can specify manifest
      # and profile file that will be used with zone installation. If you
      # specify boot option the zone will boot after successful installation.
      #
      # Steps:
      #   1) copy files to remote server
      #   REMOTE HOST
      #   2) zonecfg -z %{zonename} -f %{path_to_zonecfg}   - Create zone configuration
      #   3) zoneadm -z %{zonename} install -m %{manifest}  - Install the zone using manifest and
      #                                     -c %{profile}     profile files
      #   if boot
      #   4) zoneadm -z %{zonename} boot                    - Boot the zone if boot opt specified
      def self.deploy_rzone_from_files(zone_name, dest_host_spec, path_to_zonecfg, opts = {})
        ##########
        # OPTIONS
        copy                = opts[:copy] || true
        boot                = opts[:boot] || false
        path_to_manifest    = opts[:path_to_manifest]
        path_to_profile     = opts[:path_to_profile]
        ##########
        # PREPARATION
        cleaner             = SZONESCleanuper.new
        id                  = SZONESUtils.transaction_id
        random_id           = SZONESUtils.random_id
        tmp_dir             = opts[:tmp_dir] || '/var/tmp/'
        files_to_copy       = [path_to_zonecfg, path_to_profile, path_to_manifest]
        dest_zonecfg        = File.join(tmp_dir, "#{random_id}_#{path_to_zonecfg.split('/').last}")
        dest_manifest       = File.join(tmp_dir, "#{random_id}_#{path_to_manifest.split('/').last}")
        dest_profile        = File.join(tmp_dir, "#{random_id}_#{path_to_profile.split('/').last}")
        ##########
        # EXECUTION
        SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of zone #{zone_name} on host #{dest_host_spec[:host_name]} has been initialize...")
        SZMGMT.logger.info("DEPLOY (#{id}) -      type: FILES")
        begin
          #
          # EXECUTED ON LOCALHOST
          #
          # Copy files on remote server

          if copy
            SZMGMT.logger.info("DEPLOY (#{id}) -      Copying files #{files_to_copy.join(', ')} to directory #{dest_host_spec[:host_name]}:#{tmp_dir}...")
            SZONESBasicCommands.copy_files_on_remote_host(files_to_copy, dest_host_spec, tmp_dir).exec
            SZMGMT.logger.info("DEPLOY (#{id}) -      Copying finished.")
            # Add files to cleaner to be able to delete it after transaction
            # is finished
            files_to_copy.each do |file|
              cleaner.add_tmp_file(file, dest_host_spec)
            end
          end
          #
          # EXECUTED ON DESTINATION HOST
          #
          SZMGMT.logger.info("DEPLOY (#{id}) -      Connecting to remote host #{dest_host_spec[:host_name]}...")
          Net::SSH.start(dest_host_spec[:host_name], dest_host_spec[:user], dest_host_spec.to_h) do |ssh|
            SZONESDeploymentSubroutines.deploy_zone_from_files(zone_name,
                                                               dest_zonecfg,
                                                               {
                                                                   :id => id,
                                                                   :path_to_manifest => dest_manifest,
                                                                   :path_to_profile => dest_profile,
                                                                   :cleaner => cleaner
                                                               },
                                                               ssh,
                                                               dest_host_spec)
          end
          SZMGMT.logger.info("DEPLOY (#{id}) -      Closing connection to remote host #{dest_host_spec[:host_name]}...")
        rescue  Exceptions::SZONESError
          SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of template #{zone_name} failed.")
          cleaner.cleanup_on_failure!
        else
          if boot
            SZMGMT.logger.info("DEPLOY (#{id}) -      Booting up zone #{zone_name}")
            SZONESBasicZoneCommands.boot_zone(zone_name).exec
            SZMGMT.logger.info("DEPLOY (#{id}) -      Zone #{zone_name} booted.")
          end
          SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of template #{zone_name} succeeded.")
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Routine for deploying TEMPLATE from files on remote server. This object is composition
      # of all needed configuration files as zonecfg, manifest and profile. So
      # firstly we need to decompose the vm_spec to specified files. If you
      # specify boot option the zone will boot after successful installation.
      # Only diference from previous routine is the name of zone.
      #
      # Steps:
      #  ?0) copy files to remote server
      #   REMOTE HOST
      #   1) zonecfg -z %{zonename} -f %{path_to_zonecfg}   - Create zone configuration
      #   2) zoneadm -z %{zonename} install -m %{manifest}  - Install the zone using manifest and
      #                                     -c %{profile}     profile files
      #   if boot
      #   3) zoneadm -z %{zonename} boot                    - Boot the zone if boot opt specified
      def self.deploy_rtemplate_from_files(template_name, path_to_zonecfg, opts = {})
        full_template_name = "template_#{template_name}"
        deploy_rzone_from_files(full_template_name, path_to_zonecfg, opts)
      end
      # Routine for deploying zone from VM_SPEC on remote server. This object is composition
      # of all needed configuration files as zonecfg, manifest and profile. So
      # firstly we need to decompose the vm_spec to specified files. If you
      # specify boot option the zone will boot after successful installation.
      #
      # Steps:
      #   1) copy files to remote server
      #   REMOTE HOST
      #   2) zonecfg -z %{zonename} -f %{path_to_zonecfg}   - Create zone configuration
      #   3) zoneadm -z %{zonename} install -m %{manifest}  - Install the zone using manifest and
      #                                     -c %{profile}     profile files
      #   if boot
      #   4) zoneadm -z %{zonename} boot                    - Boot the zone if boot opt specified
      def self.deploy_rzone_from_vm_spec(zone_name, dest_host_spec, vm_spec, opts = {})
        ##########
        # OPTIONS
        copy                = opts[:copy] || true
        boot                = opts[:boot] || false
        tmp_dir             = opts[:tmp_dir] || '/var/tmp/'
        ##########
        # PREPARATION
        cleaner             = SZONESCleanuper.new
        id                  = SZONESUtils.transaction_id     # Used for marking this transaction
        random_id           = SZONESUtils.random_id          # Used for storing files during this transaction
        base_name           = "#{zone_name}_#{random_id}"    # Used for storing files during this transaction
        files_to_copy       = []
        # Prepare file from vm_spec. It means parse vm_spec and
        # export it's parts to temporary files to target machine
        zonecfg, manifest, profile = decompose_vm_spec(vm_spec)
        # Export zonecfg to file
        path_to_zonecfg = File.join(tmp_dir, "#{base_name}.zonecfg")
        zonecfg.export_configuration_to_file(path_to_zonecfg)
        cleaner.add_tmp_file(path_to_zonecfg)
        files_to_copy << path_to_zonecfg
        # Export manifest to file if it was in VM_SPEC
        if manifest
          path_to_manifest = File.join(tmp_dir, "#{base_name}.manifest.xml")
          manifest.export_manifest_to_file(path_to_manifest)
          cleaner.add_tmp_file(path_to_manifest)
          files_to_copy << path_to_manifest
        end
        # Export profile to file if it was in VM_SPEC
        if profile
          path_to_profile = File.join(tmp_dir, "#{base_name}.profile.xml")
          profile.export_profile_to_file(path_to_profile)
          cleaner.add_tmp_file(path_to_profile)
          files_to_copy << path_to_profile
        end
        ###########
        # EXECUTION
        SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of zone #{zone_name} on host #{dest_host_spec[:host_name]} has been initialize...")
        SZMGMT.logger.info("DEPLOY (#{id}) -      type: VM_SPEC")
        SZMGMT.logger.info("DEPLOY (#{id}) -   vm_spec: #{vm_spec['name']}")
        begin
          #
          # EXECUTED ON LOCALHOST
          #
          # Copy files on remote server

          if copy
            SZMGMT.logger.info("DEPLOY (#{id}) -      Copying files #{files_to_copy.join(', ')} to directory #{dest_host_spec[:host_name]}:#{tmp_dir}...")
            SZONESBasicCommands.copy_files_on_remote_host(files_to_copy, dest_host_spec, tmp_dir).exec
            SZMGMT.logger.info("DEPLOY (#{id}) -      Copying finished.")
            # Add files to cleaner to be able to delete it after transaction
            # is finished
            files_to_copy.each do |file|
              cleaner.add_tmp_file(file, dest_host_spec)
            end
          end
          #
          # EXECUTED ON DESTINATION HOST
          #
          SZMGMT.logger.info("DEPLOY (#{id}) -      Connecting to remote host #{dest_host_spec[:host_name]}...")
          Net::SSH.start(dest_host_spec[:host_name], dest_host_spec[:user], dest_host_spec.to_h) do |ssh|
            SZONESDeploymentSubroutines.deploy_zone_from_files(zone_name,
                                                               path_to_zonecfg,
                                                               {
                                                                   :id => id,
                                                                   :path_to_manifest => path_to_manifest,
                                                                   :path_to_profile => path_to_profile,
                                                                   :cleaner => cleaner
                                                               },
                                                               ssh,
                                                               dest_host_spec)
          end
          SZMGMT.logger.info("DEPLOY (#{id}) -      Closing connection to remote host #{dest_host_spec[:host_name]}...")
        rescue  Exceptions::SZONESError
          SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of template #{zone_name} failed.")
          cleaner.cleanup_on_failure!
        else
          if boot
            SZMGMT.logger.info("DEPLOY (#{id}) -      Booting up zone #{zone_name}")
            SZONESBasicZoneCommands.boot_zone(zone_name).exec
            SZMGMT.logger.info("DEPLOY (#{id}) -      Zone #{zone_name} booted.")
          end
          SZMGMT.logger.info("DEPLOY (#{id}) - Deployment of template #{zone_name} succeeded.")
        ensure
          cleaner.cleanup_temporary!
        end
      end
      # Routine for deploying TEMPLATE from VM_SPEC on remote server. This object is composition
      # of all needed configuration files as zonecfg, manifest and profile. So
      # firstly we need to decompose the vm_spec to specified files. If you
      # specify boot option the zone will boot after successful installation.
      # Only diference from previous routine is the name of zone.
      #
      # Steps:
      #   1) copy files to remote server
      #   REMOTE HOST
      #   2) zonecfg -z %{zonename} -f %{path_to_zonecfg}   - Create zone configuration
      #   3) zoneadm -z %{zonename} install -m %{manifest}  - Install the zone using manifest and
      #                                     -c %{profile}     profile files
      #   if boot
      #   4) zoneadm -z %{zonename} boot                    - Boot the zone if boot opt specified
      def self.deploy_rtemplate_from_vm_spec(template_name, vm_spec, opts = {})
        full_template_name = "template_#{template_name}"
        deploy_rtemplate_from_vm_spec(full_template_name, vm_spec, opts)
      end
    end
  end
end