require 'rails_helper'

RSpec.describe PromptEngine::ErrorHandler do
  describe '.handle_api_error' do
    context 'with HTTP errors' do
      it 'handles unauthorized errors' do
        error = Net::HTTPUnauthorized.new('401', 'Unauthorized', 'HTTP/1.1')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Invalid API key')
      end

      it 'handles rate limit errors' do
        error = Net::HTTPTooManyRequests.new('429', 'Too Many Requests', 'HTTP/1.1')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Rate limit exceeded. Please try again later.')
      end

      it 'handles general HTTP errors' do
        error = Net::HTTPError.new('500', 'Internal Server Error')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Network error. Please check your connection and try again.')
      end
    end

    context 'with message-based errors' do
      it 'handles invalid API key messages' do
        error = StandardError.new('Invalid API key provided')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Invalid API key. Please check your API key.')
      end

      it 'handles unauthorized messages' do
        error = StandardError.new('Unauthorized access')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Invalid API key. Please check your API key.')
      end

      it 'handles rate limit messages' do
        error = StandardError.new('Rate limit exceeded')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Rate limit exceeded. Please try again later.')
      end

      it 'handles network error messages' do
        error = StandardError.new('Network connection failed')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Network error. Please check your connection and try again.')
      end

      it 'handles model not found messages' do
        error = StandardError.new('Model not found')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Model not available. Please try a different model.')
      end

      it 'handles unknown errors' do
        error = StandardError.new('Something went wrong')
        result = described_class.handle_api_error(error)
        expect(result).to eq('An error occurred: Something went wrong')
      end
    end

    context 'with case insensitive matching' do
      it 'handles uppercase error messages' do
        error = StandardError.new('INVALID API KEY')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Invalid API key. Please check your API key.')
      end

      it 'handles mixed case error messages' do
        error = StandardError.new('Rate Limit Exceeded')
        result = described_class.handle_api_error(error)
        expect(result).to eq('Rate limit exceeded. Please try again later.')
      end
    end
  end
end
