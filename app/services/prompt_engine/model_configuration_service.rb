module PromptEngine
  class ModelConfigurationService
    # Default models when RubyLLM models table is not available
    # Updated with latest models from https://api.parsera.org/v1/llm-specs
    DEFAULT_MODELS = [
      # OpenAI Models (10 most popular)
      { name: "GPT-5", value: "gpt-5", provider: "openai", description: "Latest and most capable GPT model" },
      { name: "GPT-5 Mini", value: "gpt-5-mini", provider: "openai", description: "Faster, cheaper GPT-5 model" },
      { name: "GPT-5 Nano", value: "gpt-5-nano", provider: "openai", description: "Fastest, most efficient GPT-5 model" },
      { name: "GPT-4o", value: "gpt-4o", provider: "openai", description: "Most capable GPT-4 model with vision" },
      { name: "GPT-4o Mini", value: "gpt-4o-mini", provider: "openai", description: "Faster, cheaper GPT-4o" },
      { name: "GPT-4 Turbo", value: "gpt-4-turbo", provider: "openai", description: "High-performance GPT-4 with 128k context" },
      { name: "GPT-4o-2024-08-06", value: "gpt-4o-2024-08-06", provider: "openai", description: "GPT-4o snapshot from August 2024" },
      { name: "GPT-3.5 Turbo", value: "gpt-3.5-turbo", provider: "openai", description: "Fast and efficient model" },
      { name: "GPT-3.5 Turbo 16K", value: "gpt-3.5-turbo-16k", provider: "openai", description: "GPT-3.5 Turbo with 16k context" },
      
      # Anthropic Models (10 most popular)
      { name: "Claude Sonnet 4.5", value: "claude-sonnet-4-5-20250929", provider: "anthropic", description: "Latest Claude Sonnet with 200k context" },
      { name: "Claude Opus 4.1", value: "claude-opus-4-1-20250805", provider: "anthropic", description: "Most capable Claude with 200k context" },
      { name: "Claude Sonnet 4", value: "claude-sonnet-4-20250514", provider: "anthropic", description: "Claude Sonnet 4 with 200k context" },
      { name: "Claude Sonnet 3.7", value: "claude-3-7-sonnet-20250219", provider: "anthropic", description: "Claude Sonnet 3.7 with 200k context" },
      { name: "Claude Opus 4", value: "claude-opus-4-20250514", provider: "anthropic", description: "Claude Opus 4 with 200k context" },
      { name: "Claude 3.5 Sonnet", value: "claude-3-5-sonnet-20241022", provider: "anthropic", description: "Claude 3.5 Sonnet with 200k context" },
      { name: "Claude 3.5 Haiku", value: "claude-3-5-haiku-20241022", provider: "anthropic", description: "Fast and efficient Claude 3.5" },
      { name: "Claude 3 Opus", value: "claude-3-opus-20240229", provider: "anthropic", description: "Previous generation Claude Opus" },
      { name: "Claude 3 Sonnet", value: "claude-3-sonnet-20240229", provider: "anthropic", description: "Balanced Claude 3 model" },
      { name: "Claude 3 Haiku", value: "claude-3-haiku-20240307", provider: "anthropic", description: "Fastest Claude 3 model" }
    ].freeze

    class << self
      # Get available models, either from RubyLLM.models or default list
      def available_models
        load_models_from_ruby_llm
      rescue
        DEFAULT_MODELS
      end

      # Get models grouped by provider
      def models_by_provider
        available_models.group_by { |model| model[:provider] }
      end

      # Get models for a specific provider
      def models_for_provider(provider)
        available_models.select { |model| model[:provider] == provider.to_s }
      end

      # Get model options for form select
      def model_options_for_select(provider = nil)
        models = provider ? models_for_provider(provider) : available_models
        models.map { |model| [model[:name], model[:value]] }
      end

      # Get model info by value
      def find_model_by_value(value)
        available_models.find { |model| model[:value] == value }
      end

      # Check if a model is available
      def model_available?(value)
        available_models.any? { |model| model[:value] == value }
      end

      # Get the default model for a provider
      def default_model_for_provider(provider)
        case provider.to_s
        when "openai"
          "gpt-5"
        when "anthropic"
          "claude-sonnet-4-5-20250929"
        else
          available_models.first&.dig(:value)
        end
      end


      private

      # Load models from RubyLLM
      def load_models_from_ruby_llm
        return DEFAULT_MODELS unless defined?(RubyLLM) && RubyLLM.respond_to?(:models)
        
        models = RubyLLM.models
        return DEFAULT_MODELS unless models.is_a?(Array) && models.any?
        
        convert_rubyllm_models(models)
      end


      # Convert RubyLLM.models array to our format
      def convert_rubyllm_models(models)
        models.map do |model|
          # Handle different possible model formats from RubyLLM
          if model.is_a?(Hash)
            {
              name: model[:name] || model[:display_name] || model[:title],
              value: model[:value] || model[:id] || model[:name],
              provider: model[:provider] || determine_provider_from_name(model[:name] || model[:value]),
              description: model[:description] || model[:summary] || ""
            }
          elsif model.respond_to?(:name)
            {
              name: model.name || model.display_name || model.title,
              value: model.value || model.id || model.name,
              provider: model.provider || determine_provider_from_name(model.name || model.value),
              description: model.description || model.summary || ""
            }
          else
            # Fallback for string models
            model_name = model.to_s
            {
              name: model_name,
              value: model_name,
              provider: determine_provider_from_name(model_name),
              description: ""
            }
          end
        end.compact
      end

      # Determine provider from model name
      def determine_provider_from_name(name)
        return "unknown" if name.blank?
        
        name_lower = name.to_s.downcase
        case name_lower
        when /claude|anthropic/
          "anthropic"
        when /gpt|openai|davinci|curie|babbage|ada/
          "openai"
        else
          "unknown"
        end
      end

    end
  end
end
