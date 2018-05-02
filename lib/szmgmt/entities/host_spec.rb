module SZMGMT
  module Entities
    class HostSpec <  Struct.new(:host_name, :user, :keys, :non_interactive, :timeout, :keepalive, :keepalive_interval, :keepalive_maxcount, :keys_only, :verify_host_key)

      DEFAULT_OPTIONS = {
          :user => ENV['USER'],
          :keys => [ '~/.ssh/id_rsa' ],
          :non_interactive => true,
          :timeout => 10,
          :keepalive => true,
          :keepalive_interval => 120,
          :keepalive_maxcount => 720,
          :keys_only => true,
          :verify_host_key  => false
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