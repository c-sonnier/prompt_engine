module PromptEngine
  class ProviderDetectionService
    class << self
      def from_model_name(model_name)
        return nil if model_name.blank?
        
        model_lower = model_name.to_s.downcase
        
        case model_lower
        when /claude|anthropic/
          "anthropic"
        when /gpt|openai|davinci|curie|babbage|ada/
          "openai"
        else
          nil
        end
      end
    end
  end
end
