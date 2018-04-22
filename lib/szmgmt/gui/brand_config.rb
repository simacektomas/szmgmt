module SZMGMT
  module GUI
    class BrandConfig < JPanel
      MAP = {
          "Thin zone" => 'solaris',
          "Kernell zone" => 'solaris-kz',
          "Legacy" => 'solaris10'
      }

      def initialize(brand = 'solaris')
        super()
        self.setLayout GridLayout.new(1, 2)
        self.add(JLabel.new 'Zone type:')
        @brand = JComboBox.new
        @brand.addItem("Thin zone")
        @brand.addItem("Kernell zone")
        @brand.addItem("Legacy")
        if brand == 'solaris'
          @brand.setSelectedItem("Thin zone")
        elsif brand == 'solaris-kz'
          @brand.setSelectedItem('Kernell zone')
        else
          @brand.setSelectedItem("Legacy")
        end
        self.add @brand
      end

      def to_h
        {
            "brand" => "#{MAP[@brand.getSelectedItem()]}"
        }
      end
    end
  end
end