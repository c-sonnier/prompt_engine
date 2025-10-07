require "rails_helper"

module PromptEngine
  RSpec.describe "Evaluation Beta Features", type: :request do
    include Engine.routes.url_helpers
    
    let(:prompt) { create(:prompt, content: "Tell me about {{topic}}", status: "enabled") }
    let(:eval_set) { create(:eval_set, prompt: prompt, name: "Test Evaluation Set") }

    describe "GET /prompt_engine/prompts/:id" do
    it "displays evaluation data for the prompt" do
      get prompt_path(prompt)
      expect(response).to be_successful
      
      # Should now include evaluation sections that were previously commented out
      expect(response.body).to include("Evaluation Sets")
      expect(response.body).to include("New Evaluation Set")
    end
    end

    describe "GET /prompt_engine/evaluations" do
      it "displays beta marker in title" do
        get evaluations_path
        expect(response).to be_successful
        expect(response.body).to include("Evaluations (Beta)")
      end

      it "displays beta notice" do
        get evaluations_path
        expect(response.body).to include("Beta Feature:")
        expect(response.body).to include("Results may vary and functionality is subject to change")
      end
    end

    describe "GET /prompt_engine/prompts/:id/eval_sets" do
      it "displays beta marker in title" do
        get prompt_eval_sets_path(prompt)
        expect(response).to be_successful
        expect(response.body).to include("Evaluation Sets (Beta)")
      end
    end

    describe "GET /prompt_engine/prompts/:id/eval_sets/new" do
      it "displays beta marker in title" do
        get new_prompt_eval_set_path(prompt)
        expect(response).to be_successful
        expect(response.body).to include("New Evaluation Set (Beta)")
      end
    end

    describe "GET /prompt_engine/prompts/:id/eval_sets/:id" do
      it "displays beta marker in title" do
        get prompt_eval_set_path(prompt, eval_set)
        expect(response).to be_successful
        expect(response.body).to include("(Beta)")
      end
    end

    describe "GET /prompt_engine/prompts/:id/eval_sets/:id/edit" do
      it "displays beta marker in title" do
        get edit_prompt_eval_set_path(prompt, eval_set)
        expect(response).to be_successful
        expect(response.body).to include("Edit Evaluation Set (Beta)")
      end
    end

    describe "navigation menu" do
      it "includes evaluations link with beta marker" do
        get evaluations_path
        expect(response.body).to include("Evaluations (Beta)")
      end
    end
  end
end
