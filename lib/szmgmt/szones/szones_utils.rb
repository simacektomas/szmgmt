module SZMGMT
  module SZONES
    class SZONESUtils
      def self.adjust_zone_volume_name(volume_name, zone_name)
        tokens = volume_name.split('/')
        tokens[-1] = zone_name
        tokens.join('/')
      end

      # Generator of transaction id of length 8
      def self.transaction_id
        length = 8
        rand(36**length).to_s(36)
      end

      # Generator of random file name.
      def self.random_id
        length = 4
        rand(36**length).to_s(36)
      end
    end
  end
end