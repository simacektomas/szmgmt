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
        java_string = java.lang.String.new(@password.getPassword)
        unix_passwd = Crypto::HashGenerator.generate_hash(java_string.to_s)
        {
            "type" => "user",
            "values" => {
                "login" => @login.getText,
                "password" => unix_passwd,
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