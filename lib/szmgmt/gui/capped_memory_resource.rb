module SZMGMT
  module GUI
    class CappedMemoryResource < JPanel
      CAPPED_MEMORY = {
          "physical" => '',
          "locked" => '',
          "swap" => ''
      }

      def initialize(memory_hash = CAPPED_MEMORY)
        super()
        self.setLayout GridLayout.new(3, 2)
        title = BorderFactory.createTitledBorder("Capped-Memory");
        self.setBorder title
        self.add(JLabel.new 'Physical memory:')
        @physical = JTextField.new memory_hash['physical']
        self.add @physical
        self.add(JLabel.new 'Locked memory:')
        @locked = JTextField.new memory_hash['locked']
        self.add @locked
        self.add(JLabel.new 'Swap memory:')
        @swap = JTextField.new memory_hash['swap']
        self.add @swap
      end

      def to_h
        {
            "type" => "capped-memory",
            "values" => {
                "physical" => @physical.getText(),
                "locked" => @locked.getText(),
                "swap" => @swap.getText()
            }
        }
      end
    end
  end
end