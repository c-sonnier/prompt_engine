require "rails_helper"

RSpec.describe PromptEngine::WorkflowRun, type: :model do
  let(:workflow) { create(:workflow, steps: { "1" => "test-prompt" }) }
  
  before do
    # Create the prompt that the workflow references
    create(:prompt, slug: "test-prompt", name: "Test Prompt", content: "Test content")
  end
  
  it "belongs to workflow" do
    run = create(:prompt_engine_workflow_run, workflow: workflow)
    expect(run.workflow).to eq(workflow)
  end
  
  it "has completed status by default" do
    run = create(:prompt_engine_workflow_run, workflow: workflow)
    expect(run.status).to eq("completed")
  end
  
  it "validates execution_time is numeric and non-negative" do
    run = build(:prompt_engine_workflow_run, workflow: workflow, execution_time: -1)
    expect(run).not_to be_valid
    expect(run.errors[:execution_time]).to include("must be greater than or equal to 0")
  end
end
