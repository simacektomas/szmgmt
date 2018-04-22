module SZMGMT
  module CLI
    class ZoneDeployer
      def initialize(api)
        @zones_by_hosts = Hash.new { |h, k| h[k] = [] }
        @result = {}
        @host_specs = {}
        @api = api
      end

      def add_zone(zone_name, host_spec = {:host_name => 'localhost'})
        @zones_by_hosts[host_spec[:host_name]] << zone_name
        @host_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def deploy_from_spec(path_to_spec, options = {})
        force = options[:force] || false
        boot  = options[:boot] || false
        routine_options = {
            :force => force,
            :boot => boot
        }
        puts "Solaris zones deployment from virtual machine specification initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "                Boot zones: #{boot ? "enable" : "disable"}"
        puts "    Rewrite existing zones: #{force ? "enable" : "disable"}"
        puts "                    Source: specification <#{path_to_spec}>"
        puts "  ---------------------------------------------------------"
        puts "  Loading virtual machine specification."
        begin
          vm_spec = @api.load_vm_spec(path_to_spec)
        rescue SZMGMT::Exceptions::TemplateInvalidError
          STDERR.puts "  Error - Invalid virtual machine specification '#{path_to_spec}'."
          return 1
        rescue SZMGMT::Exceptions::PathInvalidError
          STDERR.puts "  Error - invalid path '#{path_to_spec}'."
          return 2
        else
          puts "  Virtual machine specification loaded."
        end
        puts "  ---------------------------------------------------------"
        puts "  Connecting concurrently to hosts '#{@host_specs.keys.join(', ')}' to perform deployment."
        result_all = Parallel.map(@zones_by_hosts.keys, in_threads: @zones_by_hosts.keys.size) do |host_name|
          Parallel.map(@zones_by_hosts[host_name], in_threads: @zones_by_hosts[host_name].size) do |zone_name|
            puts "  Processing zone '#{zone_name}' deployment on host '#{host_name}'. See log ''."
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_zone_from_vm_spec(zone_name, vm_spec, routine_options)
            else
              SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_rzone_from_vm_spec(zone_name, @host_specs[host_name].to_h, vm_spec, routine_options)
            end
          end
        end
        puts "  ---------------------------------------------------------"
        puts "  Deployment finished."
        puts "    Status:"
        @zones_by_hosts.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          @zones_by_hosts[host_name].each_with_index do |zone_name, zone_index|
            puts "        #{zone_name}: #{result_all[host_index][zone_index] ? 'success': 'failed'}"
          end
        end
      end

      def deploy_from_zone(source_zone_name, source_host_spec, options = {})
        clone = options[:clone] || false
        force = options[:force] || false
        boot  = options[:boot] || false
        routine_options = {
            :force => force,
            :boot => boot,
            :halt => false
        }
        puts "Solaris zones deployment from existing zone initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "               Clone zones: #{clone ? "enable" : "disable"}"
        puts "                Boot zones: #{boot ? "enable" : "disable"}"
        puts "    Rewrite existing zones: #{force ? "enable" : "disable"}"
        puts "                    Source: zone <#{source_zone_name}:#{source_host_spec[:host_name]}>"
        puts "  ---------------------------------------------------------"
        puts "  Halting source zone #{source_zone_name}"
        halt_zone = SZMGMT::SZONES::SZONESBasicZoneCommands.halt_zone(source_zone_name)
        if source_host_spec[:host_name] == 'localhost'
          halt_zone.exec
        else
          Net::SSH.start(source_host_spec[:host_name], source_host_spec[:user], source_host_spec.to_h) do |ssh|
            halt_zone.exec_ssh(ssh)
          end
        end
        booted = true unless halt_zone.stderr =~ /already halted/
        puts "  Zone #{source_zone_name} #{booted ? 'halted' : 'already halted'}."
        puts "  ---------------------------------------------------------"
        puts "  Connecting concurrently to hosts '#{@host_specs.keys.join(', ')}' to perform deployment from zone #{source_zone_name}."
        result_all = Parallel.map(@zones_by_hosts.keys, in_threads: @zones_by_hosts.keys.size) do |host_name|
          Parallel.map(@zones_by_hosts[host_name], in_threads: @zones_by_hosts[host_name].size) do |zone_name|
            puts "  Processing zone '#{zone_name}' deployment on host '#{host_name}'. See log ''."
            if source_host_spec[:host_name] == 'localhost'
              if host_name == 'localhost'
                # Source is local host as well as destination
                SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_zone_from_zone(zone_name, source_zone_name, routine_options)
              else
                SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_rzone_from_zone(zone_name, @host_specs[host_name], source_zone_name, routine_options)
              end
            else
              if host_name == 'localhost'
                SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_zone_from_rzone(zone_name, source_host_spec, source_zone_name, routine_options)
              elsif host_name == source_host_spec[:host_name]
                # Same remote destination as remote source
                SZMGMT::SZONES::SZONESDeploymentRoutines.rdeploy_zone_from_zone(zone_name, source_host_spec, source_zone_name, routine_options)
              else
                SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_rzone_from_rzone(zone_name, @host_specs[host_name], source_zone_name, source_host_spec, routine_options)
              end
            end
          end
        end
        if booted
          puts "  ---------------------------------------------------------"
          puts "  Booting up source zone #{source_zone_name}"
          boot_zone = SZMGMT::SZONES::SZONESBasicZoneCommands.boot_zone(source_zone_name)
          if source_host_spec[:host_name] == 'localhost'
            boot_zone.exec
          else
            Net::SSH.start(source_host_spec[:host_name], source_host_spec[:user], source_host_spec.to_h) do |ssh|
              boot_zone.exec_ssh(ssh)
            end
          end
          puts "  Zone #{source_zone_name} booted."
        end
        puts "  ---------------------------------------------------------"
        puts "  Deployment finished."
        puts "    Status:"
        @zones_by_hosts.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          @zones_by_hosts[host_name].each_with_index do |zone_name, zone_index|
            puts "        #{zone_name}: #{result_all[host_index][zone_index] ? 'success': 'failed'}"
          end
        end
      end

      def deploy_from_files(path_to_zonecfg, path_to_manifest, path_to_profile, options = {})
        force = options[:force] || false
        boot  = options[:boot] || false
        routine_options = {
            :force => force,
            :boot => boot
        }
        routine_options[:path_to_manifest] = path_to_manifest if path_to_manifest
        routine_options[:path_to_profile] = path_to_profile if path_to_manifest
        puts "Solaris zones deployment from source files initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "                Boot zones: #{boot ? "enable" : "disable"}"
        puts "    Rewrite existing zones: #{force ? "enable" : "disable"}"
        puts "                    Source: configuration <#{path_to_zonecfg}>"
        puts "                    Source: manifest <#{path_to_manifest}>" if path_to_manifest
        puts "                    Source: profile <#{path_to_profile}>" if path_to_profile
        puts "  ---------------------------------------------------------"
        puts "Connecting concurrently to hosts '#{@host_specs.keys.join(', ')}' to perform deployment."
        result_all = Parallel.map(@zones_by_hosts.keys, in_threads: @zones_by_hosts.keys.size) do |host_name|
          Parallel.map(@zones_by_hosts[host_name], in_threads: @zones_by_hosts[host_name].size) do |zone_name|
            puts "  Processing zone '#{zone_name}' deployment on host '#{host_name}'. See log ''."
            if host_name == 'localhost'
              SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_zone_from_files(zone_name, path_to_zonecfg, routine_options)
            else
              SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_rzone_from_files(zone_name, @host_specs[host_name].to_h, path_to_zonecfg, routine_options)
            end
          end
        end
        puts "  ---------------------------------------------------------"
        puts "  Deployment finished."
        puts "    Status:"
        @zones_by_hosts.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          @zones_by_hosts[host_name].each_with_index do |zone_name, zone_index|
            puts "        #{zone_name}: #{result_all[host_index][zone_index] ? 'success': 'failed'}"
          end
        end
      end
    end
  end
end