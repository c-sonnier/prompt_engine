module PromptEngine
  module ModelConfigurationConcern
    extend ActiveSupport::Concern
    
    private
    
    def load_model_configuration
      @settings = Setting.instance
      @available_models = @settings.available_models
      @models_by_provider = @settings.models_by_provider
    end
  end
end
