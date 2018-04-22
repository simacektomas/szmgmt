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