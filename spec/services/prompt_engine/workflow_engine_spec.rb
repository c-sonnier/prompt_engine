require 'rails_helper'

module PromptEngine
  RSpec.describe WorkflowEngine, type: :service do
    let!(:prompt1) { create(:prompt, slug: "greeting", content: "Hello {{name}}") }
    let!(:prompt2) { create(:prompt, slug: "analysis", content: "Analyze: {{output}}") }
    let(:workflow) do
      create(:workflow,
        name: "test-workflow",
        steps: { "1" => "greeting", "2" => "analysis" }
      )
    end
    let(:workflow_engine) { WorkflowEngine.new(workflow) }

    describe "#execute" do
      it "executes steps in correct order" do
        # Mock the rendered prompts
        allow_any_instance_of(PromptEngine::Prompt).to receive(:render).and_return(
          double(content: "Mock output")
        )

        result = workflow_engine.execute(name: "John")
        expect(result).to eq("Mock output")
      end
    end

    describe "#execute_with_steps" do
      it "returns detailed results" do
        # Mock the rendered prompts
        allow_any_instance_of(PromptEngine::Prompt).to receive(:render).and_return(
          double(content: "Mock output")
        )

        result = workflow_engine.execute_with_steps(name: "John")

        expect(result).to have_key("greeting_output")
        expect(result).to have_key("analysis_output")
        expect(result).to have_key("result")
        expect(result["result"]).to eq("Mock output")
      end
    end
  end
end
