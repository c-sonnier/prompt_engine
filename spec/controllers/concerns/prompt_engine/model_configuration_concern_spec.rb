require 'rails_helper'

RSpec.describe PromptEngine::ModelConfigurationConcern, type: :controller do
  # Create a test controller that includes the concern
  controller(ApplicationController) do
    include PromptEngine::ModelConfigurationConcern
    
    def test_action
      load_model_configuration
      render json: {
        settings: @settings.class.name,
        available_models: @available_models.class.name,
        models_by_provider: @models_by_provider.class.name
      }
    end
  end

  before do
    routes.draw do
      get 'test_action' => 'anonymous#test_action'
    end
  end

  describe '#load_model_configuration' do
    it 'loads model configuration instance variables' do
      get :test_action
      
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      
      expect(json_response['settings']).to eq('PromptEngine::Setting')
      expect(json_response['available_models']).to eq('Array')
      expect(json_response['models_by_provider']).to eq('Hash')
    end
  end
end
