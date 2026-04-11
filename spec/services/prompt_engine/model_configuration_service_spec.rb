require 'rails_helper'

RSpec.describe PromptEngine::ModelConfigurationService do
  describe '.available_models' do
    context 'when RubyLLM.models is not available' do
      before do
        hide_const('RubyLLM') if defined?(RubyLLM)
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

    context 'when RubyLLM.models is available' do
      let(:rubyllm_models) do
        [
          { name: 'GPT-4 Custom', value: 'gpt-4-custom', provider: 'openai', description: 'Custom GPT-4' },
          { name: 'Claude Custom', value: 'claude-custom', provider: 'anthropic', description: 'Custom Claude' }
        ]
      end

      before do
        stub_const('RubyLLM', double('RubyLLM'))
        allow(RubyLLM).to receive(:respond_to?).with(:models).and_return(true)
        allow(RubyLLM).to receive(:models).and_return(rubyllm_models)
      end

      it 'loads models from RubyLLM.models' do
        models = described_class.available_models
        
        expect(models).to be_an(Array)
        expect(models.length).to eq(2)
        expect(models.first[:name]).to eq('GPT-4 Custom')
        expect(models.first[:provider]).to eq('openai')
      end
    end

    context 'when RubyLLM.models returns string models' do
      let(:string_models) { ['gpt-4o', 'claude-3-5-sonnet-20241022'] }

      before do
        stub_const('RubyLLM', double('RubyLLM'))
        allow(RubyLLM).to receive(:respond_to?).with(:models).and_return(true)
        allow(RubyLLM).to receive(:models).and_return(string_models)
      end

      it 'converts string models to proper format' do
        models = described_class.available_models
        
        expect(models).to be_an(Array)
        expect(models.length).to eq(2)
        expect(models.first[:name]).to eq('gpt-4o')
        expect(models.first[:value]).to eq('gpt-4o')
        expect(models.first[:provider]).to eq('openai')
      end
    end

    context 'when RubyLLM.models returns empty array or raises error' do
      it 'falls back to default models when empty' do
        stub_const('RubyLLM', double('RubyLLM'))
        allow(RubyLLM).to receive(:respond_to?).with(:models).and_return(true)
        allow(RubyLLM).to receive(:models).and_return([])
        
        models = described_class.available_models
        expect(models).to eq(described_class::DEFAULT_MODELS)
      end

      it 'falls back to default models when error' do
        stub_const('RubyLLM', double('RubyLLM'))
        allow(RubyLLM).to receive(:respond_to?).with(:models).and_return(true)
        allow(RubyLLM).to receive(:models).and_raise(StandardError.new('API error'))
        
        models = described_class.available_models
        expect(models).to eq(described_class::DEFAULT_MODELS)
      end
    end
  end

  describe '.models_by_provider' do
    it 'groups models by provider' do
      grouped = described_class.models_by_provider
      
      expect(grouped).to be_a(Hash)
      expect(grouped.keys).to include('openai', 'anthropic')
    end
  end

  describe '.models_for_provider' do
    it 'returns models for specific provider' do
      openai_models = described_class.models_for_provider('openai')
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
      openai_models = described_class.models_for_provider('openai')
      expect(openai_options.length).to eq(openai_models.length)
    end
  end

  describe '.find_model_by_value' do
    it 'finds model by value' do
      model = described_class.find_model_by_value('gpt-4o')
      expect(model).to be_a(Hash)
      expect(model[:value]).to eq('gpt-4o')
    end

    it 'returns nil for unknown model' do
      expect(described_class.find_model_by_value('unknown-model')).to be_nil
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
    it 'returns correct defaults for known providers' do
      expect(described_class.default_model_for_provider('openai')).to eq('gpt-5')
      expect(described_class.default_model_for_provider('anthropic')).to eq('claude-sonnet-4-5-20250929')
    end

    it 'returns first available model for unknown provider' do
      expect(described_class.default_model_for_provider('unknown')).to be_present
    end
  end



end
