module SZMGMT
  module GUI
    class Package < JPanel
      def initialize(package)
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Package name:')
        @package = JTextField.new package
        self.add @package
      end

      def to_s
        @package.getText
      end
    end
  end
end