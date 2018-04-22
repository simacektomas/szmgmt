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