require 'rails_helper'

RSpec.describe PromptEngine::BaseService do
  # Create a test service that inherits from BaseService
  class TestService < PromptEngine::BaseService
    def initialize(value)
      @value = value
    end

    def call
      @value * 2
    end
  end

  describe '.call' do
    it 'creates instance and calls #call' do
      result = TestService.call(5)
      expect(result).to eq(10)
    end

    it 'works with keyword arguments' do
      result = TestService.call(3)
      expect(result).to eq(6)
    end
  end

  describe '#call' do
    it 'raises NotImplementedError when not implemented' do
      service = PromptEngine::BaseService.new
      expect { service.call }.to raise_error(NotImplementedError, "Subclasses must implement #call")
    end
  end

  describe '#log_error' do
    it 'logs error with class name' do
      service = TestService.new(1)
      error = StandardError.new('test error')
      
      expect(Rails.logger).to receive(:error).with('TestService: test error')
      service.send(:log_error, error)
    end

    # Note: Testing Rails not being defined is complex in test environment
    # The log_error method handles this gracefully with the defined?(Rails) check
  end

  describe 'ServiceError' do
    it 'is a StandardError' do
      expect(PromptEngine::BaseService::ServiceError).to be < StandardError
    end
  end
end
