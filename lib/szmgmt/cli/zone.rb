module SZMGMT
  module CLI
    class Zone

      attr_reader :zone_name

      def initialize
        @zone_name = ''
        @zone_brand = ''
        @zone_state = ''
        @zone_uuid = ''
        @zone_path = ''
        @zone_ip = ''
      end

      def initialize_from_hash(zone_hash)
        @zone_name = zone_hash['zone_name']
        @zone_brand = zone_hash['zone_brand']
        @zone_state = zone_hash['zone_state']
        @zone_uuid = zone_hash['zone_uuid']
        @zone_path = zone_hash['zone_path']
        @zone_ip = zone_hash['zone_ip']
        self
      end
      #-:zweb1-mig-shost2:installed:/system/zones/zweb1-mig-shost2:04e2735e-f356-40b5-9660-a1cc287e103a:solaris:excl:-::
      def initialize_from_string(zone, hostname)
        properties = zone.split(':')
        @zone_name = "#{properties[1]}:#{hostname}"
        @zone_state = properties[2]
        @zone_path = properties[3]
        @zone_uuid = properties[4]
        @zone_brand = properties[5]
        @zone_ip = properties[6]
        self
      end

      def to_h
        {
            'zone_name' => @zone_name,
            'zone_state' => @zone_state,
            'zone_path' => @zone_path,
            'zone_uuid' => @zone_uuid,
            'zone_brand' => @zone_brand,
            'zone_ip' => @zone_ip
        }
      end
    end
  end
end