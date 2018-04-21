import javax.swing.GroupLayout
import java.awt.event.KeyEvent
import javax.swing.JButton
import javax.swing.JComboBox
import javax.swing.JFrame
import javax.swing.JPanel
import javax.swing.JMenuBar
import javax.swing.JMenuItem
import javax.swing.JTextField
import javax.swing.JMenu
import javax.swing.JLabel
import java.lang.System
import javax.swing.JFileChooser
import javax.swing.JOptionPane;
import javax.swing.BoxLayout
import java.awt.GridBagLayout
import java.awt.BorderLayout
import javax.swing.Box
import java.awt.Dimension
import java.awt.GridLayout
import javax.swing.BorderFactory
import javax.swing.JScrollPane
import javax.swing.JPasswordField

module SZMGMT
  module GUI
    class UserProfile < JPanel
      USER =  {
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

      def initialize(user_hash = USER)
        super()
        self.setLayout GridLayout.new(7, 2)
        title = BorderFactory.createTitledBorder("User");
        self.setBorder title
        self.add(JLabel.new 'Login:')
        @login = JTextField.new user_hash['login']
        self.add @login
        self.add(JLabel.new 'Password:')
        @password = JPasswordField.new
        self.add @password
        self.add(JLabel.new 'User shell:')
        @shell = JTextField.new user_hash['shell']
        self.add @shell
        self.add(JLabel.new 'User type:')
        @user_type = JComboBox.new
        @user_type.addItem("Normal")
        @user_type.addItem("Role")
        if user_hash['type'] == 'role'
          @user_type.setSelectedItem('Role')
        end
        self.add @user_type
        self.add(JLabel.new 'Sudoers command:')
        @sudoers = JTextField.new user_hash['sudoers']
        self.add @sudoers

        self.add(JLabel.new 'User roles:')
        @roles = JTextField.new user_hash['roles'].join(', ')
        self.add @roles

        self.add(JLabel.new 'User profiles:')
        @profiles = JTextField.new user_hash['profiles'].join(', ')
        self.add @profiles
        self.revalidate
        self.repaint
      end

      def to_h
        {
            "type" => "user",
            "values" => {
                "login" => @login.getText,
                "pasword" => @password.getPassword,
                "shell" => @shell.getText,
                "type" => @user_type.getSelectedItem.downcase,
                "sudoers" => @sudoers.getText,
                "roles" => @roles.getText.split(','),
                "profiles" => @profiles.getText.split(',')
            }
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class RootProfile < JPanel
      ROOT = {
          "password" => '',
          "type" => 'role'
      }
      def initialize(root_hash = ROOT)
        super()
        self.setLayout GridLayout.new(2, 2)
        title = BorderFactory.createTitledBorder("Root");
        self.setBorder title
        self.add(JLabel.new 'Password:')
        @password = JPasswordField.new
        self.add @password
        self.add(JLabel.new 'Type')
        @root_type = JComboBox.new
        @root_type.addItem("Normal")
        @root_type.addItem("Role")
        if root_hash['type'] == 'role'
          @root_type.setSelectedItem('Role')
        end
        self.add @root_type
      end

      def to_h
        {
            "type" => "root",
            "values" => {
                "password" => @password.getPassword,
                "type" => @root_type.getSelectedItem.downcase
            }
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class TimezoneProfile < JPanel
      def initialize(timezone)
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Timezone:')
        @timezone = JTextField.new timezone
        self.add @timezone
      end

      def to_h
        {
            "timezone" => @timezone.getText
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class LocaleProfile < JPanel
      def initialize(locale)
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Locale:')
        @locale = JTextField.new locale
        self.add @locale
      end

      def to_h
        {
            "locale" => @locale.getText
        }
      end
    end
  end
end


module SZMGMT
  module GUI
    class HostnameProfile < JPanel
      def initialize(hostname)
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Hostname:')
        @hostname = JTextField.new hostname
        self.add @hostname
      end

      def to_h
        {
            "hostname" => @hostname.getText
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class IPv4Interface < JPanel
      INTERFACE = {
          "name" => 'net0',
          "address_type" => 'dhcp',
          'static_address' => '',
          "default_route" => ''
      }

      def initialize(interface = INTERFACE)
        super()
        self.setLayout GridLayout.new(4, 2)
        title = BorderFactory.createTitledBorder("Interface");
        self.setBorder title
        self.add(JLabel.new 'Interface name:')
        @name = JTextField.new interface["name"]
        self.add @name
        self.add(JLabel.new 'Address type:')
        @adress_type = JComboBox.new
        @adress_type.addItem("DHCP")
        @adress_type.addItem("Static")
        if interface["address_type"] == 'dhcp'
          @adress_type.setSelectedItem("DHCP")
        else
          @adress_type.setSelectedItem("Static")
        end
        self.add @adress_type
        self.add(JLabel.new 'Static address (IP):')
        @static = JTextField.new interface["static_address"]
        self.add @static
        self.add(JLabel.new 'Default route (IP):')
        @route = JTextField.new interface["default_route"]
        self.add @route
      end

      def to_h
        interface = {
            'name' => "#{@name.getText}",
            'address_type' => "#{@adress_type.getSelectedItem.downcase}"
        }
        interface['static_address'] = @static.getText unless @static.getText.empty?
        interface['default_route'] = @route.getText unless @route.getText.empty?
        interface
      end
    end
  end
end

module SZMGMT
  module GUI
    class Package < JPanel
      def initialize(package)
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Package name:')
        @package = JTextField.new package
        self.add @package
      end

      def to_s
        @package.getText
      end
    end
  end
end

module SZMGMT
  module GUI
    class AutobootConfig < JPanel
      def initialize(value = true)
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Boot with global zone:')
        @autoboot = JComboBox.new
        @autoboot.addItem("Enable")
        @autoboot.addItem("Disable")
        if value
          @autoboot.setSelectedItem("Enable")
        else
          @autoboot.setSelectedItem("Disable")
        end
        self.add @autoboot
      end

      def to_h
        autoboot = @autoboot.getSelectedItem() == 'Enable' ? true : false
        {
            "ip-type" => autoboot
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class ZonepathConfig < JPanel
      def initialize(zonepath = 'system/zones/%{zonename}')
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Zone image path:')
        @zonepath = JTextField.new zonepath
        self.add @zonepath
      end

      def to_h
        {
            "zonepath" => "#{@zonepath.getText}"
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class IPTypeConfig < JPanel
      def initialize(type = 'exclusive')
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Ip adress type:')
        @ip = JComboBox.new
        @ip.addItem("Exclusive")
        @ip.addItem("Shared")
        if type == 'exclusive'
          @ip.setSelectedItem("Exclusive")
        else
          @ip.setSelectedItem("Shared")
        end
        self.add @ip
      end

      def to_h
        {
            "ip-type" => "#{@ip.getSelectedItem().downcase}"
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class BrandConfig < JPanel
      MAP = {
          "Thin zone" => 'solaris',
          "Kernell zone" => 'solaris-kz',
          "Legacy" => 'solaris10'
      }

      def initialize(brand = 'solaris')
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Zone type:')
        @brand = JComboBox.new
        @brand.addItem("Thin zone")
        @brand.addItem("Kernell zone")
        @brand.addItem("Legacy")
        if brand == 'solaris'
          @brand.setSelectedItem("Thin zone")
        elsif brand == 'solaris-kz'
          @brand.setSelectedItem('Kernell zone')
        else
          @brand.setSelectedItem("Legacy")
        end
        self.add @brand
      end

      def to_h
        {
            "brand" => "#{MAP[@brand.getSelectedItem()]}"
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class AnetResource < JPanel
      DEFAULT_ANET = {
          "linkname" => "net0",
          "lower-link" => "auto",
          "mac-address" => "auto"
      }

      def initialize(anet_hash = DEFAULT_ANET)
        super()
        self.setLayout GridLayout.new(3, 2)
        title = BorderFactory.createTitledBorder("Anet");
        self.setBorder title
        self.add(JLabel.new 'Interface name')
        @linkname = JTextField.new anet_hash['linkname']
        self.add @linkname
        self.add(JLabel.new 'Physical interface')
        @lower_link = JTextField.new anet_hash['lower-link']
        self.add @lower_link
        self.add(JLabel.new 'MAC adress type')
        @mac_address = JComboBox.new
        @mac_address.addItem("Auto")
        @mac_address.addItem("Factory")
        @mac_address.addItem("Random")
        @mac_address.addItem("Default")
        self.add @mac_address
      end

      def to_h
        {
            "type" => "anet",
            "values" => {
                "linkname" => @linkname.getText(),
                "lower-link" => @lower_link.getText(),
                "mac-address" => @mac_address.getSelectedItem().downcase
            }
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class CappedCPUResource < JPanel
      CAPPED_CPU = {
          "ncpus" => ''
      }

      def initialize(cpu_hash = CAPPED_CPU)
        super()
        self.setLayout GridLayout.new(1, 2)
        title = BorderFactory.createTitledBorder("Capped-CPU");
        self.setBorder title
        self.add(JLabel.new 'Processor ratio:')
        @ncpus = JTextField.new cpu_hash['ncpus']
        self.add @ncpus
      end

      def to_h
        {
            "type" => "capped-cpu",
            "values" => {
                "ncpus" => @ncpus.getText()
            }
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class CappedMemoryResource < JPanel
      CAPPED_MEMORY = {
          "physical" => '',
          "locked" => '',
          "swap" => ''
      }

      def initialize(memory_hash = CAPPED_MEMORY)
        super()
        self.setLayout GridLayout.new(3, 2)
        title = BorderFactory.createTitledBorder("Capped-Memory");
        self.setBorder title
        self.add(JLabel.new 'Physical memory:')
        @physical = JTextField.new memory_hash['physical']
        self.add @physical
        self.add(JLabel.new 'Locked memory:')
        @locked = JTextField.new memory_hash['locked']
        self.add @locked
        self.add(JLabel.new 'Swap memory:')
        @swap = JTextField.new memory_hash['swap']
        self.add @swap
      end

      def to_h
        {
            "type" => "capped-memory",
            "values" => {
                "physical" => @physical.getText(),
                "locked" => @locked.getText(),
                "swap" => @swap.getText()
            }
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class AdminResource < JPanel
      ADMIN = {
          "user" => "",
          "auths" => ""
      }

      def initialize(admin_hash = ADMIN)
        super()
        self.setLayout GridLayout.new(2, 2)
        title = BorderFactory.createTitledBorder("Admin");
        self.setBorder title
        self.add(JLabel.new 'Username:')
        @user = JTextField.new admin_hash['user']
        self.add @user
        self.add(JLabel.new 'Authentication (login, manage, ..):')
        @auths = JTextField.new admin_hash['auths']
        self.add @auths
      end

      def to_h
        {
            "type" => "admin",
            "values" => {
                "user" => @user.getText(),
                "auths" => @auths.getText()
            }
        }
      end
    end
  end
end

module SZMGMT
  module GUI
    class DatasetResource < JPanel
      DATASET = {
          "name" => "",
          "alias" => ""
      }

      def initialize(dataset_hash = DATASET)
        super()
        self.setLayout GridLayout.new(2, 2)
        title = BorderFactory.createTitledBorder("Dataset");
        self.setBorder title
        self.add(JLabel.new 'Dataset name:')
        @name = JTextField.new dataset_hash['name']
        self.add @name
        self.add(JLabel.new 'Dataset alias:')
        @alias = JTextField.new dataset_hash['alias']
        self.add @alias
      end

      def to_h
        {
            "type" => "dataset",
            "values" => {
                "name" => @name.getText(),
                "alias" => @alias.getText()
            }
        }
      end
    end
  end
end

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

      def initialize
        super "Virtual machine specification editor"
        self.initialize_gui
        @loaded = false
        @loaded_vm_spec
      end

      def initialize_gui
        @scene = self.getContentPane
        @scene.setLayout BorderLayout.new

        @menu = JMenuBar.new
        file_menu = JMenu.new "File"
        item_new = JMenuItem.new 'New specification'
        item_new.addActionListener do |e|
          @loaded_vm_spec = DEFAULT_VM_SPEC
          spec_name = JOptionPane.showInputDialog("Specification name: ");
          @loaded_vm_spec['name'] = spec_name
          @loaded = true
          initialize_editor
        end
        item_open = JMenuItem.new 'Open specification'
        item_open.addActionListener do |e|
          puts 'Open clicked.'
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
        p @specification
      end

      def initialize_main
        @main_panel = JPanel.new
        @main_panel.setLayout BoxLayout.new @main_panel, BoxLayout::X_AXIS

        @scroll_panel = JScrollPane.new(@main_panel)

        @controll = JPanel.new
        @controll.setLayout GridLayout.new(1, 2)
        @validate_btn = JButton.new 'Validate specification'
        @validate_btn.addActionListener do |e|
          get_specification
        end
        @save_btn = JButton.new 'Save specification'
        @save_btn.addActionListener do |e|
          get_specification
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

