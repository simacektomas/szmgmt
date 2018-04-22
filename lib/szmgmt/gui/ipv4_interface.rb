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