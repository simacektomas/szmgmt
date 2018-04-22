module SZMGMT
  module CLI
    class HostManager
      @@default_index = [
        'localhost'
      ]

      def initialize
        @specs_dir = File.join(CLI.configuration[:root_dir],  CLI.configuration[:specs_dir])
        @index_path = File.join(@specs_dir, CLI.configuration[:index])
        # Load index
        Dir.mkdir(@specs_dir) unless File.exists?(@specs_dir)
        File.open(@index_path, 'w') {|f| f.write(@@default_index.to_json)} unless File.exists?(@index_path)
        @index = load_index
      end

      def add_host(host_spec)
        return if @index.include? host_spec[:host_name]
        @index << host_spec[:host_name]
        write_index
        write_host(host_spec)
      end

      def remove_host(hostname)
        return unless @index.include? hostname
        @index = @index - [hostname]
        write_index
        File.delete(File.join(@specs_dir, "#{hostname}_spec.json"))
      end

      def load_host_spec(hostname)
        load_host(hostname)
      end

      def load_all_hosts
        specs = []
        @index.each do |hostname|
          next if hostname == 'localhost'
          specs << load_host(hostname)
        end
      end

      private

      def load_index
        begin
          json_raw = File.read(@index_path)
          JSON.parse(json_raw)
        rescue Errno::ENOENT
          nil
        rescue JSON::ParserError
          nil
        end
      end

      def write_index
        begin
          File.open(@index_path,'w') do |file|
            file.write(@index.to_json)
          end
        rescue Errno::ENOENT
          false
        end
        true
      end

      def write_host(host_specs)
        file_name = File.join(@specs_dir, "#{host_specs[:host_name]}_spec.json")
        begin
          File.open(file_name,'w') do |file|
            file.write(host_specs.to_h.to_json)
          end
        rescue Errno::ENOENT
          false
        end
        true
      end

      def load_host(hostname)
        file_name = File.join(@specs_dir, "#{hostname}_spec.json")
        begin
          json_raw = File.read(file_name)
          hash = JSON.parse(json_raw)
          hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        rescue Errno::ENOENT
          nil
        rescue JSON::ParserError
          nil
        end
      end
    end
  end
end