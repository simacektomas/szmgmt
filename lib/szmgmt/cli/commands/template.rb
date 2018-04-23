module SZMGMT
  module CLI
    module Commands
      class Template < Thor
        def initialize(*args)
          super(*args)
          @template_deployer = SZMGMT::CLI::TemplateDeployer.new
        end

        def self.command_name
          name.split('::').last.downcase
        end

        def self.subcommand_names
          sub = []
          public_instance_methods(false).each do |m|
            sub << m.to_s
          end
          sub
        end

        def self.usage
          "#{command_name} [SUBCOMMAND]"
        end

        def self.description
          "Default desription of `#{command_name}` command. CHANGE IT!"
        end

        method_option :all,
                      aliases: ['-a'],
                      type: :boolean,
                      default: true,
                      desc: 'Determine if the template should be installed on all registered hosts.'

        method_option :hosts,
                      aliases: ['-h'],
                      type: :array,
                      desc: 'Hosts separated by comma on which the template should be installed.'

        method_option :specification,
                      aliases: ['-s'],
                      type: :string,
                      desc: 'Path to virtual machine specification that provide the configuration.',
                      required: true

        method_option :force,
                      aliases: ['-f'],
                      type: :boolean,
                      default: false,
                      desc: 'Determine if it should rewrite existing template.'


        desc 'create [TEMPLATE]', 'Create zone that will be used as template for next deployment.'
        def create(template_name)
          if options[:hosts]
            options[:hosts].each do |hostname|
              if hostname == 'localhost'
                @template_deployer.add_localhost
              else
                host_spec = CLI.host_manager.load_host_spec(hostname)
                unless host_spec
                  host_spec = SZMGMT::Entities::HostSpec.new(hostname)
                  STDERR.puts "Warning: Using default host specification for host #{hostname}. Register the host."
                end
                @template_deployer.add_host(host_spec)
              end
            end
          else
            CLI.host_manager.load_all_hosts.each do |hostname|
              if hostname == 'localhost'
                @template_deployer.add_localhost
              else
                host_spec = CLI.host_manager.load_host_spec(hostname)
                unless host_spec
                  host_spec = SZMGMT::Entities::HostSpec.new(hostname)
                  STDERR.puts "Warning: Using default host specification for host #{hostname}. Register the host."
                end
                @template_deployer.add_host(host_spec)
              end
            end
          end
          unless template_name =~ /^template/
            template_name = "template_#{template_name}"
          end
          @template_deployer.deploy_template(template_name, options[:specification], {:force => options[:force]})
        end

        method_option :all,
                      aliases: ['-a'],
                      type: :boolean,
                      default: true,
                      desc: 'Determine if the template should be removed from all registered hosts.'

        method_option :hosts,
                      aliases: ['-h'],
                      type: :array,
                      desc: 'Hosts separated by comma on which the template should be destroyed.'

        desc 'destroy [TEMPLATE]', 'Destroy the zone template.'
        def destroy(template_name)
          if options[:hosts]
            options[:hosts].each do |hostname|
              if hostname == 'localhost'
                @template_deployer.add_localhost
              else
                host_spec = CLI.host_manager.load_host_spec(hostname)
                unless host_spec
                  host_spec = SZMGMT::Entities::HostSpec.new(hostname)
                  STDERR.puts "Warning: Using default host specification for host #{hostname}. Register the host."
                end
                @template_deployer.add_host(host_spec)
              end
            end
          else
            CLI.host_manager.load_all_hosts.each do |hostname|
              if hostname == 'localhost'
                @template_deployer.add_localhost
              else
                host_spec = CLI.host_manager.load_host_spec(hostname)
                unless host_spec
                  host_spec = SZMGMT::Entities::HostSpec.new(hostname)
                  STDERR.puts "Warning: Using default host specification for host #{hostname}. Register the host."
                end
                @template_deployer.add_host(host_spec)
              end
            end
          end
          unless template_name =~ /^template/
            template_name = "template_#{template_name}"
          end
          @template_deployer.destroy_template(template_name)
        end
      end
    end
  end
end