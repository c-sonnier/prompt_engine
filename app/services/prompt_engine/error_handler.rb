module PromptEngine
  class ErrorHandler
    class << self
      def handle_api_error(error)
        case error
        when Net::HTTPUnauthorized
          "Invalid API key"
        when Net::HTTPTooManyRequests
          "Rate limit exceeded. Please try again later."
        when Net::HTTPError
          "Network error. Please check your connection and try again."
        else
          handle_message_based_error(error)
        end
      end
      
      private
      
      def handle_message_based_error(error)
        error_message = error.message.to_s.downcase
        
        case error_message
        when /invalid.*api.?key/i, /unauthorized/i, /invalid x-api-key/i
          "Invalid API key. Please check your API key."
        when /rate limit/i
          "Rate limit exceeded. Please try again later."
        when /network/i, /connection/i
          "Network error. Please check your connection and try again."
        when /model.*not found/i
          "Model not available. Please try a different model."
        else
          "An error occurred: #{error.message}"
        end
      end
    end
  end
end
