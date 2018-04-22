module SZMGMT
  module CLI
    class MainCLI < Thor
      @@configuration = {
          :root_dir => File.join(ENV['HOME'], '.szmgmt')
      }

      def initialize(*args)
        super(*args)
        self.class.initialize_cli
        @host_manager = CLI::HostManager.new
        @szmgmt_api = SZMGMT::SZMGMTAPI.new
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

      class_option :force,
                   aliases: ['-f'],
                   desc: 'Determine if the installation, migration process should rewrite existing zones.',
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

      desc 'editor', 'Editor for virtual machine specification'
      def editor
        SZMGMT::GUI::SpecEditor.new(@szmgmt_api)
      end

      desc 'list', 'List all zones on registered hosts.'
      def list
        host_specs = []
        @host_manager.load_all_hosts.each do |hostname|
          next if hostname == 'localhost'
          host_specs << @host_manager.load_host_spec(hostname)
        end

        zones = []
        host_specs.each do |host_spec|
          host_zones = SZMGMT::SZONES::SZONESBasicRoutines.list_zones(host_spec)
          host_zones.each do |zone|
            zone[:name] = "#{zone[:name]}:#{host_spec[:host_name]}"
            zones << zone
          end
        end
        zones += SZMGMT::SZONES::SZONESBasicRoutines.list_zones
        tp zones, zones.first.keys
      end

      method_option :boot,
                    aliases: ['-b'],
                    type: :boolean,
                    default: false,
                    desc: 'Determine if the created zone should be booted.'

      method_option :clone,
                    type: :boolean,
                    default: true,
                    desc: 'Usable only with template and zone options. Determine if zone should be cloned.'

      method_option :interactive,
                    aliases: ['-i'],
                    type: :boolean,
                    desc: 'Show if interactive installation should be executed.'

      method_option :template,
                    aliases: ['-t'],
                    type: :string,
                    desc: 'Determine existing template from witch zones should be created.'

      method_option :zone,
                    aliases: ['-z'],
                    type: :string,
                    desc: 'Determine existing zone from witch zones should be created. Zone identifier.'

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
        deployer = ZoneDeployer.new(@szmgmt_api)
        parse_zone_identifiers(deployer, *zone_identifiers)
        if options[:interactive]
          if RUBY_PLATFORM =~ /java/
            interactive_install = SZMGMT::GUI::InteractiveInstall.new @szmgmt_api
            if interactive_install.saved
              deployer.deploy_from_spec(interactive_install.specification,
                                        {:force => options[:force], :boot => options[:boot]})
            end
          else

          end
        elsif options[:template]

        elsif options[:zone]
          zone_name, hostname = options[:zone].split(':')
          if hostname
            host_spec = @host_manager.load_host_spec(hostname)
            # Create default spec for this host
            unless host_spec
              SZMGMT.logger.warn("Using default host_spec values for host #{hostname}")
              host_spec = SZMGMT::Entities::HostSpec.new(hostname).to_h
            end
          else
            host_spec = {:host_name => 'localhost'}
          end
          deployer.deploy_from_zone(zone_name,
                                    host_spec,
                                    {:force => options[:force], :boot => options[:boot], :clone => options[:clone]})
        elsif options[:spec]
          deployer.deploy_from_spec(options[:spec],
                                    {:force => options[:force], :boot => options[:boot]})

        elsif options[:zonecfg]
          deployer.deploy_from_files(options[:zonecfg],
                                     options[:manifest],
                                     options[:profile],
                                    {:force => options[:force], :boot => options[:boot]})
        else
          if RUBY_PLATFORM =~ /java/
            interactive_install = SZMGMT::GUI::InteractiveInstall.new @szmgmt_api
            interactive_install.setVisible true
            if interactive_install.saved
              deployer.deploy_from_spec(interactive_install.specification,
                                        {:force => options[:force], :boot => options[:boot]})
            end
          else

          end
        end
      end

      method_option :destination,
                    aliases: ['-d'],
                    type: :string,
                    default: 'localhost',
                    desc: 'Hostname that is final destination of migrated zones.'

      method_option :type,
                    aliases: ['-t'],
                    enum: %w{d z u},
                    default: 'z',
                    desc: 'Type of migration to use. Types are d = direct, z = zfs archive, u = unified archive.'

      desc 'migrate [ZONE_ID, ...]', 'Migrate zones specified by zone id to specified host.'
      def migrate(*zone_identifiers)
        if options[:destination] == 'localhost'
          dest_host_spec = SZMGMT::Entities::HostSpec.new(Socket.gethostname).to_h
        else
          dest_host_spec = @host_manager.load_host_spec(options[:destination])
          unless dest_host_spec
            SZMGMT.logger.warn("Using default host_spec values for destination #{options[:destination]}")
            dest_host_spec = SZMGMT::Entities::HostSpec.new(options[:destination]).to_h
          end
        end
        migrator = ZoneMigrator.new(dest_host_spec)
        zone_identifiers.each do |zone_id|
          zone_name, hostname = zone_id.split(':')
          if hostname
            host_spec = @host_manager.load_host_spec(hostname)
            # Create default spec for this host
            unless host_spec
              SZMGMT.logger.warn("Using default host_spec values for host #{hostname}")
              host_spec = SZMGMT::Entities::HostSpec.new(hostname).to_h
            end
            migrator.add_zone(zone_name, host_spec)
          else
            migrator.add_zone(zone_name)
          end
        end
        case options[:type]
        when 'd'
          migrator.migrate_directly
        when 'z'
          migrator.migrate_zfs
        when 'u'
          migrator.migrate_uar
        else
          SZMGMT.logger.error("Invalid type of migration type")
        end
      end

      desc 'backup [ZONE_ID, ...]', 'Backup all specified zone to specified path.'

      method_option :destination,
                    aliases: ['-d'],
                    type: :string,
                    desc: 'Hostname that is final destination of backuped zones.'

      method_option :path,
                    aliases: ['-p'],
                    type: :string,
                    default: '/var/tmp',
                    desc: 'Path where the backups should be stored. Combination with destination options will copy files on remote host.'

      method_option :type,
                    aliases: ['-t'],
                    enum: %w{zfs uar},
                    default: 'zfs',
                    desc: 'Type of migration to use. Types are d = direct, z = zfs archive, u = unified archive.'

      def backup(*zone_identifiers)
        return if zone_identifiers.empty?
        backuper = ZoneBackuper.new
        zone_identifiers.each do |zone_id|
          zone_name, hostname = zone_id.split(':')
          if hostname
            host_spec = @host_manager.load_host_spec(hostname)
            # Create default spec for this host
            unless host_spec
              SZMGMT.logger.warn("Using default host_spec values for host #{hostname}")
              host_spec = SZMGMT::Entities::HostSpec.new(hostname).to_h
            end
            backuper.add_zone_to_backup(zone_name, host_spec)
          else
            backuper.add_zone_to_backup(zone_name)
          end
        end
        dest_hostname = options[:destination]
        if dest_hostname
          archive_destination = @host_manager.load_host_spec(dest_hostname)
          # Create default spec for this host
          unless archive_destination
            SZMGMT.logger.warn("Using default host_spec values for destination #{dest_hostname}")
            archive_destination = SZMGMT::Entities::HostSpec.new(dest_hostname).to_h
          end
        end
        if options[:type] == 'zfs'
          backuper.backup_using_zfs_archives(options[:path], archive_destination)
        else
          backuper.backup_using_uar(options[:path], archive_destination)
        end
      end

      private

      def parse_zone_identifiers(handler, *zone_identifiers)
        zone_identifiers.each do |zone_id|
          zone_name, hostname = zone_id.split(':')
          if hostname
            host_spec = @host_manager.load_host_spec(hostname)
            # Create default spec for this host
            unless host_spec
              SZMGMT.logger.warn("Using default host_spec values for host #{hostname}")
              host_spec = SZMGMT::Entities::HostSpec.new(hostname).to_h
            end
            handler.add_zone(zone_name, host_spec)
          else
            handler.add_zone(zone_name)
          end
        end
      end
    end
  end
end