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
        java_string = java.lang.String.new(@password.getPassword)
        unix_passwd = Crypto::HashGenerator.generate_hash(java_string.to_s)
        {
            "type" => "root",
            "values" => {
                "password" => unix_passwd,
                "type" => @root_type.getSelectedItem.downcase
            }
        }
      end
    end
  end
end