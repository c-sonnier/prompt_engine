require 'rails_helper'

RSpec.describe PromptEngine::ParameterProcessingConcern, type: :controller do
  # Create a test controller that includes the concern
  controller(ApplicationController) do
    include PromptEngine::ParameterProcessingConcern
    
    def test_action
      result = process_parameters_with_files
      render json: result
    end
  end

  before do
    routes.draw do
      post 'test_action' => 'anonymous#test_action'
    end
  end

  describe '#process_parameters_with_files' do
    context 'with no files' do
      it 'returns parameters without files' do
        post :test_action, params: { parameters: { name: 'test', value: 'example' } }
        
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        
        expect(json_response['name']).to eq('test')
        expect(json_response['value']).to eq('example')
        expect(json_response['files']).to be_nil
      end
    end

    context 'with files' do
      let(:file1) { fixture_file_upload('test.txt', 'text/plain') }
      let(:file2) { fixture_file_upload('test.pdf', 'application/pdf') }

      it 'includes files in parameters' do
        post :test_action, params: { 
          parameters: { name: 'test' }, 
          files: [file1, file2] 
        }
        
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        
        expect(json_response['name']).to eq('test')
        expect(json_response['files']).to be_present
        expect(json_response['files'].length).to eq(2)
      end
    end

    context 'with empty files' do
      it 'filters out empty files' do
        post :test_action, params: { 
          parameters: { name: 'test' }, 
          files: ['', nil, '   '] 
        }
        
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        
        expect(json_response['name']).to eq('test')
        expect(json_response['files']).to be_nil
      end
    end
  end
end
