module SZMGMT
  module SZONES
    module Entities
      class SZONEProfile
        @@templates = {
            :timezone => 'timezone_service_template.xml',
            :locale => 'locale_service_template.xml',
            :hostname => 'hostname_service_template.xml',
            :users => 'user_service_template.xml',
            :user => 'user_account_template.xml',
            :root => 'root_account_template.xml',
            :network_physical => 'network_physical_service_template.xml',
            :network_install => 'network_install_service_template.xml',
            :ipv4_interface => 'ipv4_interface_template.xml',
            :system => 'system_template.xml'
        }

        def initialize(vm_spec_profile)
          @vm_spec_profile = vm_spec_profile
          @process_service = ['users', 'network']
          @services = []
          @template_dir = SZMGMT::SZONES.configuration[:profile_template_dir]
          @network_processed = false
          parse_profile
        end

        def export_profile
          system_template_path = File.join(@template_dir, @@templates[:system])
          system_template = load_template(system_template_path)
          profile = system_template % { :services => @services.join("\n") }
          # Remove unfilled lines => Their will have %% sequence
          # in it
          output = ''
          profile.each_line do |line|
            output << line unless line =~ /%%/
          end
          output
        end

        def export_profile_to_file(path_to_file)
          File.open(path_to_file, 'w') do |file|
            file.write(export_manifest)
          end
        end

        private

        def parse_profile
          @vm_spec_profile.each do |service_name, value|
            if @process_service.include? service_name
              self.send("process_#{service_name}", value)
            else
              # Load template
              template_path = File.join(@template_dir, @@templates[service_name.to_sym])
              template = load_template(template_path)
              # Fill template
              @services << template % {service_name.to_sym => value}
            end
          end
          # Network will be determined by user
          template_path = File.join(@template_dir, @@templates[:network_physical])
          template = load_template(template_path)
          if @network_processed
            @services << template % { :type => 'DefaultFixed'}
          # Network will be determined by automatic
          else
            @services << template % { :type => 'Automatic' }
          end
        end

        def process_users(users)
          processed_users = []
          users.each do |user|
            if user['type'] == 'root'
              processed_users << process_root(user['values'])
            else
              processed_users << process_user(user['values'])
            end
          end
          # Load user service template
          users_template_path = File.join(@template_dir, @@templates[:users])
          users_template = load_template(users_template_path)

          @services << users_template % {:user_accounts => processed_users.join("\n")}
        end

        def process_network(interfaces)
          return if interfaces.empty?
          # Process all interfaces in interfaces array
          procesed_interfaces = []
          interfaces.each do |interface|
            procesed_interfaces << process_interface(interface)
          end
          # Load template for network install service
          # and fill it with processed interfaces.
          network_install_path = File.join(@template_dir, @@templates[:network_install])
          network_install = load_template(network_install_path)
          # Add network install service to profile
          @services << network_install % {:interfaces => procesed_interfaces.join("\n")}
          @network_processed = true
        end

        def process_interface(interface)
          # Make keys of interface hash symbols
          interface =  interface.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
          # Make hash fill keys that are not in spec
          # with char %% that will be erased at the end
          interface.default_proc = proc { |h, k| "%%" }
          # Load interface account template
          interface_template_path = File.join(@template_dir, @@templates[:ipv4_interface])
          interface_template = load_template(interface_template_path)
          # Fill template
          interface_template % interface
        end

        def process_root(root)
          # Make keys of root hash symbols
          root = root.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
          # Make hash fill keys that are not in spec
          # with char %% that will be erased at the end
          root.default_proc = proc { |h, k| "%%" }
          # Load root account template
          root_template_path = File.join(@template_dir, @@templates[:root])
          root_template = load_template(root_template_path)
          # Fill template
          root_template % root
        end

        def process_user(user)
          # Make keys of user hash symbols
          user = user.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
          # Join the arrays of roles and profiles properties
          tmp = {}
          user.each do |key, value|
            if value.is_a? Array
              tmp[key] = value.join(',')
            else
              tmp[key] = value
            end
          end
          user = tmp
          # Make hash fill keys that are not in spec
          # with char %% that will be erased at the end
          user.default_proc = proc { |h, k| "%%" }
          # Load user account template
          user_template_path = File.join(@template_dir, @@templates[:user])
          user_template = load_template(user_template_path)
          # Fill template
          user_template % user
        end

        def load_template(template_path)
          template = ''
          File.open(template_path, 'r') do |file|
            file.each_line do |line|
              template << line
            end
          end
          template
        end
      end
    end
  end
end