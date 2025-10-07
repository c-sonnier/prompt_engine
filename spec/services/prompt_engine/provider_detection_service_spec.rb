require 'rails_helper'

RSpec.describe PromptEngine::ProviderDetectionService do
  describe '.from_model_name' do
    context 'with Anthropic models' do
      it 'detects Claude models' do
        expect(described_class.from_model_name('claude-3-5-sonnet')).to eq('anthropic')
        expect(described_class.from_model_name('claude-3-opus')).to eq('anthropic')
        expect(described_class.from_model_name('claude-sonnet-4')).to eq('anthropic')
      end

      it 'detects Anthropic models' do
        expect(described_class.from_model_name('anthropic-claude')).to eq('anthropic')
      end
    end

    context 'with OpenAI models' do
      it 'detects GPT models' do
        expect(described_class.from_model_name('gpt-4')).to eq('openai')
        expect(described_class.from_model_name('gpt-3.5-turbo')).to eq('openai')
        expect(described_class.from_model_name('gpt-5')).to eq('openai')
      end

      it 'detects OpenAI models' do
        expect(described_class.from_model_name('openai-gpt-4')).to eq('openai')
      end

      it 'detects legacy OpenAI models' do
        expect(described_class.from_model_name('davinci')).to eq('openai')
        expect(described_class.from_model_name('curie')).to eq('openai')
        expect(described_class.from_model_name('babbage')).to eq('openai')
        expect(described_class.from_model_name('ada')).to eq('openai')
      end
    end

    context 'with unknown models' do
      it 'returns nil for unknown models' do
        expect(described_class.from_model_name('unknown-model')).to be_nil
        expect(described_class.from_model_name('gemini-pro')).to be_nil
      end

      it 'returns nil for blank input' do
        expect(described_class.from_model_name('')).to be_nil
        expect(described_class.from_model_name(nil)).to be_nil
        expect(described_class.from_model_name('   ')).to be_nil
      end
    end

    context 'with case insensitive matching' do
      it 'works with uppercase models' do
        expect(described_class.from_model_name('GPT-4')).to eq('openai')
        expect(described_class.from_model_name('CLAUDE-3-5-SONNET')).to eq('anthropic')
      end

      it 'works with mixed case models' do
        expect(described_class.from_model_name('Gpt-4')).to eq('openai')
        expect(described_class.from_model_name('Claude-3-5-Sonnet')).to eq('anthropic')
      end
    end
  end
end
