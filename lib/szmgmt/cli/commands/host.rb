module SZMGMT
  module CLI
    module Commands
      class Host < Thor
        def initialize(*args)
          super(*args)
          @host_manager = CLI::HostManager.new
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
          "#{command_name} [#{subcommand_names.join('|')}]"
        end

        def self.description
          "Used for managing hosts for szmgmt application"
        end
        method_option :user,
                      aliases: ['-u'],
                      type: :string,
                      default: ENV['USER'],
                      desc: 'User that will be used to login on this host'

        method_option :keys,
                      aliases: ['-k'],
                      type: :array,
                      default: [ '~/.ssh/id_rsa' ],
                      desc: 'Private keys that will be used to connect on this host'

        desc 'add hostname', 'Add this host to registered hosts. Use options for specifying details.'
        def add(hostname)
          host_spec = SZMGMT::Entities::HostSpec.new(hostname)
          host_spec[:user] = options[:user]
          host_spec[:keys] = options[:keys]
          p host_spec.to_h
          @host_manager.add_host(host_spec.to_h)
        end

        desc 'delete hostname', 'Delete this host from registered hosts.'
        def delete(hostname)
          @host_manager.remove_host(hostname)
        end

        desc 'delete hostname', 'Delete this host from registered hosts.'
        def list
          puts 'Hosts:'
          @host_manager.load_all_host_specs.each do |host|
            puts "  #{host}"
          end
        end
      end
    end
  end
end