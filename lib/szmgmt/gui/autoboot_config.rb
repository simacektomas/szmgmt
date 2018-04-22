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