module PromptEngine
  class Setting < ApplicationRecord
    self.table_name = "prompt_engine_settings"

    # Rails automatically encrypts these attributes
    encrypts :openai_api_key
    encrypts :anthropic_api_key

    # Singleton pattern - only one settings record should exist
    def self.instance
      first_or_create!
    end

    # Check if API keys are configured
    def openai_configured?
      openai_api_key.present?
    end

    def anthropic_configured?
      anthropic_api_key.present?
    end

    # Get masked API key for display (show only first and last 3 characters)
    def masked_openai_api_key
      mask_api_key(openai_api_key)
    end

    def masked_anthropic_api_key
      mask_api_key(anthropic_api_key)
    end

    # Model configuration methods
    def available_models
      @available_models ||= ModelConfigurationService.available_models
    end

    def models_by_provider
      @models_by_provider ||= ModelConfigurationService.models_by_provider
    end

    def models_for_provider(provider)
      ModelConfigurationService.models_for_provider(provider)
    end

    def model_options_for_select(provider = nil)
      ModelConfigurationService.model_options_for_select(provider)
    end

    def find_model_by_value(value)
      ModelConfigurationService.find_model_by_value(value)
    end

    def model_available?(value)
      ModelConfigurationService.model_available?(value)
    end

    def default_model_for_provider(provider)
      ModelConfigurationService.default_model_for_provider(provider)
    end

    # Get model configuration preferences
    def model_preferences
      preferences || {}
    end

    def model_preferences=(new_preferences)
      self.preferences = (preferences || {}).merge(new_preferences)
    end

    # Get enabled models (if user has configured specific models to show)
    def enabled_models
      model_preferences["enabled_models"] || available_models.map { |m| m[:value] }
    end

    def enabled_models=(model_values)
      model_preferences["enabled_models"] = model_values
    end

    # Get filtered models based on user preferences
    def filtered_models(provider = nil)
      models = provider ? models_for_provider(provider) : available_models
      enabled_model_values = enabled_models
      
      if enabled_model_values.any?
        models.select { |model| enabled_model_values.include?(model[:value]) }
      else
        models
      end
    end

    private

    def mask_api_key(key)
      return nil if key.blank?
      return "*****" if key.length <= 6

      # Show first 3 characters, then ..., then last 3 characters
      # e.g., "sk-abc123xyz789" becomes "sk-...789"
      first_part = key[0..2]  # First 3 characters
      last_part = key[-3..]   # Last 3 characters
      "#{first_part}...#{last_part}"
    end
  end
end
