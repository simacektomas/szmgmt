module SZMGMT
  singleton_class.class_eval do
    def configure
      reset
      yield config
      self
    end

    def reset
      @configuration = nil
      self
    end

    def config
      @config ||= Configuration.new
    end

    def templates
      @templates = Templates::TemplateManager.new(config)
    end
  end
end
