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