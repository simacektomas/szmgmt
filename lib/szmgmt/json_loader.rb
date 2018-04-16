module SZMGMT
  class JSONLoader
    def self.load_json(path_to_json)
      begin
        json_raw = File.read(path_to_json)
        JSON.parse(json_raw)
      rescue Errno::ENOENT
        raise SZMGMT::Exceptions::PathInvalidError.new(path_to_json)
      rescue JSON::ParserError
        raise SZMGMT::Exceptions::JSONParseError.new(path_to_json)
      end
    end
  end
end