module SZMGMT
  class Configuration < Struct.new(:root_dir, :schema_dir)
    DEFAULT_OPTIONS = {
        root_dir: '/etc/szmgmt/',
        schema_dir: '/etc/szmgmt/schema'
    }

    def initialize(options = {})
      DEFAULT_OPTIONS.merge(options).each do |option, value|
        self[option] = value
      end
    end
  end
end
