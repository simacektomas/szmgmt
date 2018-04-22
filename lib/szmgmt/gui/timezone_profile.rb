module SZMGMT
  module GUI
    class TimezoneProfile < JPanel
      def initialize(timezone)
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Timezone:')
        @timezone = JTextField.new timezone
        self.add @timezone
      end

      def to_h
        {
            "timezone" => @timezone.getText
        }
      end
    end
  end
end