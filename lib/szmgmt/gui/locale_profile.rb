module SZMGMT
  module GUI
    class LocaleProfile < JPanel
      def initialize(locale)
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Locale:')
        @locale = JTextField.new locale
        self.add @locale
      end

      def to_h
        {
            "locale" => @locale.getText
        }
      end
    end
  end
end