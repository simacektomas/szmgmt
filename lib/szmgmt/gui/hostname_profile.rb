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