module SZMGMT
  module GUI
    class DatasetResource < JPanel
      DATASET = {
          "name" => "",
          "alias" => ""
      }

      def initialize(dataset_hash = DATASET)
        super()
        self.setLayout GridLayout.new(2, 2)
        title = BorderFactory.createTitledBorder("Dataset");
        self.setBorder title
        self.add(JLabel.new 'Dataset name:')
        @name = JTextField.new dataset_hash['name']
        self.add @name
        self.add(JLabel.new 'Dataset alias:')
        @alias = JTextField.new dataset_hash['alias']
        self.add @alias
      end

      def to_h
        {
            "type" => "dataset",
            "values" => {
                "name" => @name.getText(),
                "alias" => @alias.getText()
            }
        }
      end
    end
  end
end