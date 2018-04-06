module SZMGMT
  singleton_class.class_eval do
    def configure
      reset
      yield config
      self
    end

    def reset
      @configuration = nil
    end

    def config
      @config ||= Configuration.new
    end
  end
end
