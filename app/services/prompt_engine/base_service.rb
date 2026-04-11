module PromptEngine
  class BaseService
    class ServiceError < StandardError; end
    
    def self.call(*args, **kwargs)
      new(*args, **kwargs).call
    end
    
    def call
      raise NotImplementedError, "Subclasses must implement #call"
    end
    
    private
    
    def log_error(error)
      Rails.logger.error("#{self.class.name}: #{error.message}") if defined?(Rails)
    end
  end
end
