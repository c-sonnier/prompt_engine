require 'rails_helper'

RSpec.describe PromptEngine::ModelConfigurationService do
  describe '.available_models' do
    context 'when RubyLLM models table does not exist' do
      before do
        allow(described_class).to receive(:ruby_llm_models_table_exists?).and_return(false)
      end

      it 'returns default models' do
        models = described_class.available_models
        
        expect(models).to be_an(Array)
        expect(models.length).to be > 0
        
        # Check that we have models from both providers
        providers = models.map { |m| m[:provider] }.uniq
        expect(providers).to include('openai', 'anthropic')
        
        # Check that each model has required attributes
        models.each do |model|
          expect(model).to have_key(:name)
          expect(model).to have_key(:value)
          expect(model).to have_key(:provider)
          expect(model).to have_key(:description)
        end
      end
    end

    context 'when RubyLLM models table exists' do
      let(:mock_model_class) { double('RubyLLM::Model') }
      let(:mock_models) do
        [
          double('Model', name: 'GPT-4 Custom', value: 'gpt-4-custom', provider: 'openai', description: 'Custom GPT-4'),
          double('Model', name: 'Claude Custom', value: 'claude-custom', provider: 'anthropic', description: 'Custom Claude')
        ]
      end

      before do
        allow(described_class).to receive(:ruby_llm_models_table_exists?).and_return(true)
        allow(described_class).to receive(:find_ruby_llm_model_class).and_return(mock_model_class)
        allow(mock_model_class).to receive(:all).and_return(mock_models)
      end

      it 'loads models from RubyLLM table' do
        models = described_class.available_models
        
        expect(models).to be_an(Array)
        expect(models.length).to eq(2)
        expect(models.first[:name]).to eq('GPT-4 Custom')
        expect(models.first[:provider]).to eq('openai')
      end
    end
  end

  describe '.models_by_provider' do
    it 'groups models by provider' do
      models = described_class.available_models
      grouped = described_class.models_by_provider
      
      expect(grouped).to be_a(Hash)
      expect(grouped.keys).to include('openai', 'anthropic')
      
      grouped.each do |provider, provider_models|
        expect(provider_models).to all(have_key(:provider))
        expect(provider_models).to all(satisfy { |m| m[:provider] == provider })
      end
    end
  end

  describe '.models_for_provider' do
    it 'returns models for specific provider' do
      openai_models = described_class.models_for_provider('openai')
      
      expect(openai_models).to be_an(Array)
      expect(openai_models).to all(satisfy { |m| m[:provider] == 'openai' })
    end
  end

  describe '.model_options_for_select' do
    it 'returns options for form select' do
      options = described_class.model_options_for_select
      
      expect(options).to be_an(Array)
      expect(options.first).to be_an(Array)
      expect(options.first.length).to eq(2) # [display_name, value]
    end

    it 'filters by provider when specified' do
      openai_options = described_class.model_options_for_select('openai')
      
      expect(openai_options).to be_an(Array)
      # All options should be from OpenAI models
      openai_models = described_class.models_for_provider('openai')
      expect(openai_options.length).to eq(openai_models.length)
    end
  end

  describe '.find_model_by_value' do
    it 'finds model by value' do
      # Use a known model value from default models
      model = described_class.find_model_by_value('gpt-4o')
      
      expect(model).to be_a(Hash)
      expect(model[:value]).to eq('gpt-4o')
    end

    it 'returns nil for unknown model' do
      model = described_class.find_model_by_value('unknown-model')
      
      expect(model).to be_nil
    end
  end

  describe '.model_available?' do
    it 'returns true for available model' do
      expect(described_class.model_available?('gpt-4o')).to be true
    end

    it 'returns false for unavailable model' do
      expect(described_class.model_available?('unknown-model')).to be false
    end
  end

  describe '.default_model_for_provider' do
    it 'returns correct default for OpenAI' do
      expect(described_class.default_model_for_provider('openai')).to eq('gpt-5')
    end

    it 'returns correct default for Anthropic' do
      expect(described_class.default_model_for_provider('anthropic')).to eq('claude-sonnet-4-5-20250929')
    end

    it 'returns first available model for unknown provider' do
      default = described_class.default_model_for_provider('unknown')
      expect(default).to be_present
    end
  end

  describe '.ruby_llm_models_table_exists?' do
    context 'when RubyLLM is not defined' do
      before do
        hide_const('RubyLLM') if defined?(RubyLLM)
      end

      it 'returns false' do
        expect(described_class.send(:ruby_llm_models_table_exists?)).to be false
      end
    end

    context 'when RubyLLM is defined but no models table' do
      before do
        stub_const('RubyLLM', Module.new)
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_return(false)
      end

      it 'returns false' do
        expect(described_class.send(:ruby_llm_models_table_exists?)).to be false
      end
    end
  end
end
