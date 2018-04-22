module SZMGMT
  module GUI
    class SpecEditor < JFrame
      DEFAULT_VM_SPEC = {
          "name" => "default",
          "type" => "szones",
          "configuration" => {
              "brand" => "solaris",
              "zonepath" => "/system/zones/%{zonename}",
              "autoboot" => '',
              "ip-type" => "exclusive",
              "resources" => [
                  {
                      "type" => "anet",
                      "values" => {
                          "linkname" => "net0",
                          "lower-link" => "auto",
                          "mac-address" => "auto"
                      }
                  }
              ]
          },
          "manifest" => {
              "packages" => []
          },
          "profile" => {
              "hostname" => "solaris",
              "timezone" => "Europe/Prague",
              "locale" => "en_US.UTF-8",
              "users" => [
                  {
                      "type" => "root",
                      "values" => {
                          "password" => '',
                          "type" => 'role'
                      }
                  },
                  {
                      "type" => "user",
                      "values" => {
                          "login" => 'user',
                          "pasword" => '',
                          "shell" => "/bin/bash",
                          "type" => "normal",
                          "sudoers" => "ALL=(ALL) ALL",
                          "roles" => [
                              "root"
                          ],
                          "profiles" => [
                              "System Administrator"
                          ]
                      }
                  }
              ],
              "network" => [
                  {
                      "name" => "net0",
                      "address_type" => "dhcp",
                  }
              ]
          }
      }

      def initialize(szmgmt_api)
        super "Virtual machine specification editor"
        self.initialize_gui
        @loaded = false
        @loaded_vm_spec
        @api = szmgmt_api
      end

      def initialize_gui
        @scene = self.getContentPane
        @scene.setLayout BorderLayout.new

        @menu = JMenuBar.new
        file_menu = JMenu.new "File"
        item_new = JMenuItem.new 'New specification'
        item_new.addActionListener do |e|
          @loaded_vm_spec = DEFAULT_VM_SPEC
          @loaded = true
          initialize_editor
        end
        item_open = JMenuItem.new 'Open specification'
        item_open.addActionListener do |e|

          spec_chooser = JFileChooser.new
          ret = spec_chooser.showOpenDialog self
          if ret == JFileChooser::APPROVE_OPTION
            selectedFile = spec_chooser.getSelectedFile();
            path = selectedFile.getAbsolutePath();

            @loaded_vm_spec = @api.load_vm_spec path
            @loaded = true
            initialize_editor
          else
            JOptionPane.showMessageDialog(self,
                                          "You didn't choose a virtual machine specification file.",
                                          "Warning",
                                          JOptionPane::WARNING_MESSAGE)
          end
        end
        item_exit = JMenuItem.new "Exit"
        item_exit.addActionListener do |e|
          System.exit 0
        end

        file_menu.add item_new
        file_menu.add item_open
        file_menu.add item_exit
        @menu.add file_menu
        self.setJMenuBar @menu

        @info = JPanel.new
        @info.setLayout BoxLayout.new @info, BoxLayout::X_AXIS
        @info.add JLabel.new("Welcome #{ENV['USER']} to virtual machine specification editor.")

        @scene.add @info, BorderLayout::PAGE_START

        self.setDefaultCloseOperation JFrame::EXIT_ON_CLOSE
        self.setSize 250, 200
        self.setLocationRelativeTo nil
        self.pack
        self.setVisible true
      end

      def initialize_editor
        initialize_main
        initialize_configuration @loaded_vm_spec["configuration"]
        initialize_manifest @loaded_vm_spec["manifest"]
        initialize_profile @loaded_vm_spec["profile"]
        self.pack
      end

      def get_specification
        @specification = {
            "configuration" => {
                "resources" => []
            },
            "manifest" => {
                "packages" => []
            },
            "profile" => {
                "users" => [],
                "network" => []
            }
        }
        @configuration_global.getComponents.each do |global_config|
          @specification["configuration"].merge! global_config.to_h
        end

        @configuration_resources.getComponents.each do |resource|
          @specification["configuration"]["resources"] << resource.to_h
        end

        @manifest_packages.getComponents.each do |package|
          @specification["manifest"]["packages"] << package.to_s
        end

        @profile_global.getComponents.each do |global_profile|
          @specification["profile"].merge! global_profile.to_h
        end

        @profile_users.getComponents.each do |user|
          @specification["profile"]["users"] << user.to_h
        end

        @profile_interfaces.getComponents.each do |interface|
          @specification["profile"]["network"] << interface.to_h
        end
        { 'name' => @loaded_vm_spec['name'], 'type' => @loaded_vm_spec['type'] }.merge @specification
      end

      def initialize_main
        @scene.removeAll()
        @main_panel = JPanel.new
        @main_panel.setLayout BoxLayout.new @main_panel, BoxLayout::X_AXIS

        @scroll_panel = JScrollPane.new(@main_panel)

        @controll = JPanel.new
        @controll.setLayout GridLayout.new(1, 2)
        @validate_btn = JButton.new 'Validate specification'
        @validate_btn.addActionListener do |e|
          vm_spec = get_specification
          begin
            @api.validate_vm_spec('', false, vm_spec)
            JOptionPane.showMessageDialog(self,
                                          "Virtual machine specification is valid.",
                                          "Info",
                                          JOptionPane::INFORMATION_MESSAGE)
          rescue SZMGMT::Exceptions::TemplateInvalidError => e
            JOptionPane.showMessageDialog(self,
                                          "Virtual machine specification is invalid.",
                                          "Warning",
                                          JOptionPane::WARNING_MESSAGE)
          end
        end
        @save_btn = JButton.new 'Save specification'
        @save_btn.addActionListener do |e|
          vm_spec = get_specification
          spec_name = JOptionPane.showInputDialog("Specification name: ");
          return unless spec_name
          vm_spec['name'] = spec_name

          spec_chooser = JFileChooser.new
          spec_chooser.setCurrentDirectory(java.io.File.new("~/"))
          spec_chooser.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY)
          ret = spec_chooser.showOpenDialog self
          if ret == JFileChooser::APPROVE_OPTION
            selectedFile = spec_chooser.getSelectedFile();
            path = selectedFile.getAbsolutePath();
            file_path = File.join(path, "#{spec_name}.json")
            if File.exist?(file_path)
              choice = JOptionPane.showConfirmDialog(self,
                                                     "File #{file_path} exists.\nDo you want to overwrite it ?",
                                                     "Warning",
                                                     JOptionPane::YES_NO_OPTION,
                                                     JOptionPane::QUESTION_MESSAGE)
              return if choice == 1
            end
            File.open(file_path,"w") do |file|
              file.write(JSON.pretty_generate(vm_spec))
            end
            @scene.removeAll()
            self.pack
          end
        end
        @controll.add @validate_btn
        @controll.add @save_btn

        @scene.add @controll, BorderLayout::PAGE_END
        @scene.add @scroll_panel, BorderLayout::CENTER
      end

      ############################################################################################################################
      def initialize_configuration(configuration)
        # Initialize panel
        @configuration = JPanel.new
        @configuration.setLayout BorderLayout.new
        title = BorderFactory.createTitledBorder("Configuration");
        @configuration.setBorder title

        @configuration_wrapper = JPanel.new
        @configuration_wrapper.setLayout GridLayout.new(2,1)

        @configuration_global = JPanel.new
        @configuration_global.setLayout BoxLayout.new(@configuration_global, BoxLayout::Y_AXIS)

        @configuration_resources = JPanel.new
        @configuration_resources.setLayout BoxLayout.new(@configuration_resources, BoxLayout::Y_AXIS)
        @resources = []

        configuration.keys.each do |key|
          if key != 'resources'
            if key == 'brand'
              @configuration_global.add BrandConfig.new(configuration[key])
            elsif key == 'ip-type'
              @configuration_global.add IPTypeConfig.new(configuration[key])
            elsif key == 'autoboot'
              @configuration_global.add AutobootConfig.new(configuration[key])
            elsif key == 'zonepath'
              @configuration_global.add ZonepathConfig.new(configuration[key])
            end

          else
            configuration[key].each do |resource|
              case resource["type"]
              when 'anet'
                anet = AnetResource.new(resource['values'])
                @resources << anet
                @configuration_resources.add anet
              when 'capped_memory'
                capped_memory = CappedMemoryResource.new(resource['values'])
                @resources << capped_memory
                @configuration_resources.add capped_memory
              when 'capped_cpu'
                capped_cpu = CappedCPUResource.new(resource['values'])
                @resources << capped_cpu
                @configuration_resources.add capped_cpu
              when 'dataset'
                dataset = DatasetResource.new(resource['values'])
                @resources << dataset
                @configuration_resources.add dataset
              when 'admin'
                admin = AdminResource.new(resource['values'])
                @resources << admin
                @configuration_resources.add admin
              end
            end
          end
        end


        @configuration_controll = JPanel.new
        @configuration_controll.setLayout GridLayout.new(1,3)
        @configuration_add = JButton.new 'Add resource'
        @configuration_add.addActionListener do |e|
          case @configuration_resource.getSelectedItem
          when "Automatic network"
            add_anet
          when 'Capped-CPU'
            add_capped_cpu
          when 'Capped-Memory'
            add_capped_memory
          when 'Admin'
            add_admin
          when 'Dataset'
            add_dataset
          end
        end
        @configuration_resource = JComboBox.new
        @configuration_resource.addItem('Automatic network')
        @configuration_resource.addItem('Admin')
        @configuration_resource.addItem('Capped-CPU')
        @configuration_resource.addItem('Capped-Memory')
        @configuration_resource.addItem('Dataset')
        @configuration_del = JButton.new 'Delete resource'
        @configuration_del.addActionListener do |e|
          remove_resource
        end
        @configuration_controll.add @configuration_add
        @configuration_controll.add @configuration_resource
        @configuration_controll.add @configuration_del

        @configuration_wrapper.add @configuration_global
        @configuration_wrapper.add @configuration_resources

        @configuration.add @configuration_wrapper, BorderLayout::CENTER
        @configuration.add @configuration_controll, BorderLayout::PAGE_END

        @main_panel.add @configuration
      end

      def remove_resource
        return if @resources.size == 0
        resource = @resources.pop
        @configuration_resources.remove(resource)
        @configuration_resources.revalidate()
        @configuration_resources.repaint
      end

      def add_anet
        anet = AnetResource.new
        @resources << anet
        @configuration_resources.add anet
        @configuration_resources.revalidate()
        @configuration_resources.repaint

      end

      def add_capped_cpu
        capped_cpu = CappedCPUResource.new
        @resources << capped_cpu
        @configuration_resources.add capped_cpu
        @configuration_resources.revalidate()
        @configuration_resources.repaint
      end

      def add_capped_memory
        capped_memory = CappedMemoryResource.new
        @resources << capped_memory
        @configuration_resources.add capped_memory
        @configuration_resources.revalidate()
        @configuration_resources.repaint
      end

      def add_admin
        admin = AdminResource.new
        @resources << admin
        @configuration_resources.add admin
        @configuration_resources.revalidate()
        @configuration_resources.repaint
      end

      def add_dataset
        dataset = DatasetResource.new
        @resources << dataset
        @configuration_resources.add dataset
        @configuration_resources.revalidate()
        @configuration_resources.repaint
      end
      ############################################################################################################################
      def initialize_manifest(manifest)
        # Initialize panel
        @manifest = JPanel.new
        @manifest.setLayout BorderLayout.new
        title = BorderFactory.createTitledBorder("Manifest");
        @manifest.setBorder title

        @packages = []
        @manifest_controll = JPanel.new
        @manifest_controll.setLayout GridLayout.new(1, 2)
        @package_add = JButton.new 'Add package'
        @package_add.addActionListener do |e|
          add_package
        end
        @package_del = JButton.new 'Remove package'
        @package_del.addActionListener do |e|
          remove_package
        end
        @manifest_controll.add @package_add
        @manifest_controll.add @package_del

        @manifest_packages = JPanel.new
        @manifest_packages.setLayout BoxLayout.new(@manifest_packages, BoxLayout::Y_AXIS)
        title = BorderFactory.createTitledBorder("Packages");

        @manifest_packages.setBorder title
        manifest['packages'].each do |package|
          tmp = Package.new(package)
          @packages << tmp
          @manifest_packages.add tmp
        end

        @manifest.add @manifest_packages, BorderLayout::CENTER
        @manifest.add @manifest_controll, BorderLayout::PAGE_END

        @main_panel.add @manifest
      end

      def remove_package
        return if @packages.size == 0
        package = @packages.pop
        @manifest_packages.remove(package)
        @manifest_packages.revalidate()
        @manifest_packages.repaint
      end

      def add_package
        package = Package.new('')
        @packages << package
        @manifest_packages.add package
        @manifest_packages.revalidate()
        @manifest_packages.repaint
      end
      ############################################################################################################################
      def initialize_profile(profile)
        # Initialize panel
        @profile = JPanel.new
        @profile.setLayout BorderLayout.new
        title = BorderFactory.createTitledBorder("Settings");
        @profile.setBorder title

        @profile_wrapper = JPanel.new
        @profile_wrapper.setLayout GridLayout.new(3,1)

        @profile_global = JPanel.new
        @profile_global.setLayout BoxLayout.new(@profile_global, BoxLayout::Y_AXIS)

        @profile_users = JPanel.new
        @profile_users.setLayout BoxLayout.new(@profile_users, BoxLayout::Y_AXIS)
        title = BorderFactory.createTitledBorder("Users");
        @profile_users.setBorder title

        @interfaces = []
        @profile_interfaces = JPanel.new
        @profile_interfaces.setLayout BoxLayout.new(@profile_interfaces, BoxLayout::Y_AXIS)
        title = BorderFactory.createTitledBorder("Interfaces");
        @profile_interfaces.setBorder title

        @profile_controll = JPanel.new
        @profile_controll.setLayout GridLayout.new(1, 2)

        profile.keys.each do |key|
          if key == 'users'
            profile[key].each do |user|
              if user['type'] == 'root'
                @profile_users.add RootProfile.new user['values']
                self.pack
              else
                @profile_users.add UserProfile.new user['values']
                self.pack
              end
            end
          elsif key == 'network'
            profile[key].each do |interface|
              tmp = IPv4Interface.new interface
              @interfaces << tmp
              @profile_interfaces.add tmp
              @profile_interfaces.revalidate()
              @profile_interfaces.repaint
              self.pack
            end
          else
            if key == 'hostname'
              @profile_global.add HostnameProfile.new profile[key]
            elsif key == 'locale'
              @profile_global.add LocaleProfile.new profile[key]
            elsif key == 'timezone'
              @profile_global.add TimezoneProfile.new profile[key]
            end
          end
        end

        @interface_add = JButton.new 'Add interface'
        @interface_add.addActionListener do |e|
          add_interface
        end
        @interface_del = JButton.new 'Remove interface'
        @interface_del.addActionListener do |e|
          remove_interface
        end
        @profile_controll.add @interface_add
        @profile_controll.add @interface_del

        @profile_wrapper.add @profile_global
        @profile_wrapper.add @profile_users
        @profile_wrapper.add @profile_interfaces

        @profile.add @profile_wrapper, BorderLayout::CENTER
        @profile.add @profile_controll, BorderLayout::PAGE_END

        @main_panel.add @profile
      end

      def add_interface
        interface = IPv4Interface.new
        @interfaces << interface
        @profile_interfaces.add interface
        @profile_interfaces.revalidate()
        @profile_interfaces.repaint
        self.pack
      end

      def remove_interface
        return if @interfaces.size <= 0
        interface = @interfaces.pop
        @profile_interfaces.remove interface
        @profile_interfaces.revalidate()
        @profile_interfaces.repaint
        self.pack
      end
    end
  end
end

