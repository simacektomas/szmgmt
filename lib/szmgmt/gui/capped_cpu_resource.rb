module SZMGMT
  module GUI
    class CappedCPUResource < JPanel
      CAPPED_CPU = {
          "ncpus" => ''
      }

      def initialize(cpu_hash = CAPPED_CPU)
        super()
        self.setLayout GridLayout.new(1, 2)
        title = BorderFactory.createTitledBorder("Capped-CPU");
        self.setBorder title
        self.add(JLabel.new 'Processor ratio:')
        @ncpus = JTextField.new cpu_hash['ncpus']
        self.add @ncpus
      end

      def to_h
        {
            "type" => "capped-cpu",
            "values" => {
                "ncpus" => @ncpus.getText()
            }
        }
      end
    end
  end
end