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
      # Get available models, either from RubyLLM models table or default list
      def available_models
        if ruby_llm_models_table_exists?
          load_models_from_ruby_llm
        else
          DEFAULT_MODELS
        end
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

      # Check if RubyLLM models table exists
      def ruby_llm_models_table_exists?
        return false unless defined?(ActiveRecord)
        
        begin
          # Try to access the RubyLLM models table
          # This assumes RubyLLM uses a standard Rails model structure
          if defined?(RubyLLM) && RubyLLM.const_defined?(:Model)
            model_class = RubyLLM::Model
            # Check if it's a class that responds to table_exists?
            if model_class.is_a?(Class) && model_class.respond_to?(:table_exists?)
              model_class.table_exists?
            else
              # If it's a module or doesn't have table_exists?, check for table directly
              ActiveRecord::Base.connection.table_exists?("ruby_llm_models") ||
              ActiveRecord::Base.connection.table_exists?("rubyllm_models") ||
              ActiveRecord::Base.connection.table_exists?("models")
            end
          elsif defined?(RubyLLM) && RubyLLM.const_defined?(:Models)
            models_class = RubyLLM::Models
            if models_class.is_a?(Class) && models_class.respond_to?(:table_exists?)
              models_class.table_exists?
            else
              # If it's a module or doesn't have table_exists?, check for table directly
              ActiveRecord::Base.connection.table_exists?("ruby_llm_models") ||
              ActiveRecord::Base.connection.table_exists?("rubyllm_models") ||
              ActiveRecord::Base.connection.table_exists?("models")
            end
          else
            # Try to find the models table directly
            ActiveRecord::Base.connection.table_exists?("ruby_llm_models") ||
            ActiveRecord::Base.connection.table_exists?("rubyllm_models") ||
            ActiveRecord::Base.connection.table_exists?("models")
          end
        rescue => e
          Rails.logger.debug "RubyLLM models table check failed: #{e.message}" if defined?(Rails)
          false
        end
      end

      private

      # Load models from RubyLLM models table
      def load_models_from_ruby_llm
        begin
          # Try different possible model class names
          model_class = find_ruby_llm_model_class
          return DEFAULT_MODELS unless model_class

          # Load models from the table
          models = model_class.all.map do |model|
            {
              name: model.name || model.title || model.display_name,
              value: model.value || model.id || model.name,
              provider: determine_provider_from_model(model),
              description: model.description || model.summary || ""
            }
          end

          # Fallback to default if no models found
          models.any? ? models : DEFAULT_MODELS
        rescue => e
          Rails.logger.warn "Failed to load models from RubyLLM: #{e.message}" if defined?(Rails)
          DEFAULT_MODELS
        end
      end

      # Find the RubyLLM model class
      def find_ruby_llm_model_class
        return nil unless defined?(RubyLLM)

        # Try different possible class names
        [
          RubyLLM::Model,
          RubyLLM::Models,
          RubyLLM::ModelRecord,
          RubyLLM::ModelsRecord
        ].find do |klass|
          klass && 
          klass.is_a?(Class) && 
          klass.respond_to?(:table_exists?) && 
          klass.table_exists?
        end
      rescue
        nil
      end

      # Determine provider from model attributes
      def determine_provider_from_model(model)
        # Check various attributes that might indicate the provider
        name = (model.name || model.value || "").to_s.downcase
        provider = model.provider if model.respond_to?(:provider)
        provider ||= model.api_provider if model.respond_to?(:api_provider)
        
        # Fallback to name-based detection
        provider ||= case name
        when /claude|anthropic/
          "anthropic"
        when /gpt|openai|davinci|curie|babbage|ada/
          "openai"
        else
          "unknown"
        end

        provider.to_s
      end
    end
  end
end
