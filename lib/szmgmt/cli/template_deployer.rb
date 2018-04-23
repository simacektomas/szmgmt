module SZMGMT
  module CLI
    class TemplateDeployer
      def initialize
        @hosts = []
        @host_specs = {}
      end

      def add_localhost
        @hosts << 'localhost'
        @host_specs['localhost'] = {:host_name => 'localhost'}
      end

      def add_host(host_spec)
        @hosts << host_spec[:host_name]
        @host_specs[host_spec[:host_name]] = host_spec
      end

      def deploy_template(template_name, path_to_spec, options = {})
        force = options[:force] || false
        routine_options = {
            :force => force,
            :boot => false
        }
        puts "Solaris template deployment from virtual machine specification initialized."
        puts "  ---------------------------------------------------------"
        puts "  Options:"
        puts "    Rewrite existing templates: #{force ? "enable" : "disable"}"
        puts "                        Source: specification <#{path_to_spec}>"
        puts "  ---------------------------------------------------------"
        puts "  Loading virtual machine specification."
        begin
          vm_spec = CLI.api.load_vm_spec(path_to_spec)
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
        puts "  Connecting concurrently to hosts '#{@hosts.join(', ')}' to perform template deployment."
        result_all = Parallel.map(@host_specs.keys, in_threads: @host_specs.keys.size) do |host_name|
          puts "    Deploying template #{template_name} on host #{host_name}..."
          if host_name == 'localhost'
            SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_zone_from_vm_spec(template_name, vm_spec, routine_options)
          else
            SZMGMT::SZONES::SZONESDeploymentRoutines.deploy_rzone_from_vm_spec(template_name, @host_specs[host_name].to_h, vm_spec, routine_options)
          end
        end
        puts "  ---------------------------------------------------------"
        puts "  Deployment finished."
        puts "    Status:"
        @host_specs.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          puts "        #{template_name}: #{result_all[host_index] ? 'success': 'failed'}"
          CLI.zone_tracker.track_zone("#{template_name}:#{host_name}") if result_all[host_index]
        end
      end

      def destroy_template(template_name, options = {})
        force = options[:force] || true
        puts "Solaris template destroy initialized."
        puts "  ---------------------------------------------------------"
        puts "  Loading virtual machine specification."
        puts "  Connecting concurrently to hosts '#{@hosts.join(', ')}' to perform template deployment."
        result_all = Parallel.map(@host_specs.keys, in_threads: @host_specs.keys.size) do |host_name|
          puts "    Destroying template #{template_name} on host #{host_name}..."
          if host_name == 'localhost'
            SZMGMT::SZONES::SZONESBasicRoutines.remove_zone(template_name)
          else
            Net::SSH.start(@host_specs[host_name][:host_name], @host_specs[host_name][:user], @host_specs[host_name].to_h) do |ssh|
              SZMGMT::SZONES::SZONESBasicRoutines.remove_zone(template_name, ssh)
            end
          end
        end
        puts "  ---------------------------------------------------------"
        puts "  Destroy finished."
        puts "    Status:"
        @host_specs.keys.each_with_index do |host_name, host_index|
          puts "      #{host_name}:"
          puts "        #{template_name}: #{result_all[host_index] ? 'success': 'failed'}"
          CLI.zone_tracker.untrack_zone("#{template_name}:#{host_name}") if result_all[host_index]
        end
      end
    end
  end
end