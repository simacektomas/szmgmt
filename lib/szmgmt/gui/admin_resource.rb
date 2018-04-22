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