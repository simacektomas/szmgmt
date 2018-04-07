module SZMGMT
  class ConnectionSpecBuilder
    attr_reader :specification

    DEFAULT_VALUES = {
        :user => ENV['USER'],
        :auth_methods => [ Net::SSH::Authentication::Methods::Hostbased,
                           Net::SSH::Authentication::Methods::Publickey ],
        :keys => [ '~/.ssh/id_rsa' ]
    }

    def initialize(hostname)
      @specification ||= { :hostname => hostname }
      @specification.merge!(DEFAULT_VALUES)
    end

    def user=(user)
      @specification[:user] = user
    end

    def auth_methods=(methods)
      @specification[:auth_methods] = methods
    end

    def keys=(keys)
      @specification[:keys] = keys
    end
  end
end