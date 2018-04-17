module SZMGMT
  module CLI
    class MainCLI < Thor
      @@configuration = {
          :root_dir => File.join(ENV['HOME'], '.szmgmt')
      }

      def self.configuration

      end

      def initialize(*args)
        super
        self.class.initialize_cli
        @host_manager = CLI::HostManager.new
      end

      def self.initialize_cli
        # Initialize directory
        Dir.mkdir(@@configuration[:root_dir]) unless File.exists?(@@configuration[:root_dir])
      end

      class_option :verbose,
                   aliases: ['-v'],
                   desc: 'Makes command to print more detailed informations',
                   type: :boolean,
                   default: false


      # Automatic load of all subcommands
      # in Commands module
      Commands.constants.each do |c|
        command = Commands.const_get(c)
        next if (!command.is_a? Class)
        register(command,
                 command.command_name,
                 command.usage,
                 command.description)
      end

      method_option :template,
                    aliases: ['-t'],
                    type: :string,
                    desc: 'Determine existing template from witch zones should be created.'

      method_option :zone,
                    aliases: ['-z'],
                    type: :string,
                    desc: 'Determine existing zone from witch zones should be created.'

      method_option :spec,
                    aliases: ['-s'],
                    type: :string,
                    desc: 'Path to virtual machine specification from witch zones should be created.'

      method_option :zonecfg,
                    aliases: ['-c'],
                    type: :string,
                    desc: 'Path to command file. It can be exported from zonecfg(1) command and contains zone configuration.'

      method_option :manifest,
                    aliases: ['-m'],
                    type: :string,
                    desc: 'Path manifest file that contains software that should be install to zone.'

      method_option :profile,
                    aliases: ['-p'],
                    type: :string,
                    desc: 'Path profile file that contains configuration for system. See sysconfig(1).'

      desc 'deploy [ZONE_ID, ...]', 'Deploy zones by their identifiers. Id is in format of <zonename:hostname>'
      def deploy(*zone_identifiers)
        zones.each do |zone|
          puts zone
        end
      end

      method_option :destination,
                    aliases: ['-d'],
                    type: :string,
                    desc: 'Hostname that is final destination of migrated zones.'

      method_option :type,
                    aliases: ['-t'],
                    enum: %w{d z u},
                    desc: 'Type of migration to use. Types are d = direct, z = zfs archive, u = unified archive.'

      desc 'migrate [ZONE_ID, ...]', 'Migrate zones specified by zone id to specified host.'
      def migrate(*zone_identifiers)

      end

      desc 'backup [ZONE_ID, ...]', 'Backup all specified zone to specified path.'

      method_option :destination,
                    aliases: ['-d'],
                    type: :string,
                    desc: 'Hostname that is final destination of backuped zones.'

      method_option :path,
                    aliases: ['-p'],
                    type: :string,
                    desc: 'Path where the backups should be stored. Combination with destination options will copy files on remote host.'

      method_option :type,
                    aliases: ['-t'],
                    enum: %w{d z u},
                    desc: 'Type of migration to use. Types are d = direct, z = zfs archive, u = unified archive.'
      def backup(*zone_identifiers)
        return if zone_identifiers.empty?

        zone_identifiers.each do |zone_id|
          tokens = zone_id.split(':')
          zone_name = tokens.first

        end
      end
    end
  end
end