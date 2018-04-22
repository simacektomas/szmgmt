module SZMGMT
  module Entities
    class HostSpec <  Struct.new(:host_name, :user, :keys, :non_interactive, :timeout)

      DEFAULT_OPTIONS = {
          :user => ENV['USER'],
          :keys => [ '~/.ssh/id_rsa' ],
          :non_interactive => true,
          :timeout => 1000
      }

      def initialize(hostname, options = {})
        self[:host_name] = hostname
        DEFAULT_OPTIONS.merge(options).each do |option, value|
          self[option] = value
        end
      end
    end
  end
end