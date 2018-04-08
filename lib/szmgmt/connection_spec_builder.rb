module SZMGMT
  class ConnectionSpecBuilder
    attr_reader :specification

    DEFAULT_VALUES = {
        :user => ENV['USER'],
        :keys => [ '~/.ssh/id_rsa' ],
        :non_interactive => true
    }

    def initialize(hostname)
      @specification ||= { :host_name => hostname }
      @specification.merge!(DEFAULT_VALUES)
    end

    def user=(user)
      @specification[:user] = user
    end

    def keys=(keys)
      @specification[:keys] = keys
    end

    def non_interactive=(value)
      @specification[:non_interactive] = value
    end
  end
end