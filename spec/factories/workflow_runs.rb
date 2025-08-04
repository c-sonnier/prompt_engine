FactoryBot.define do
  factory :prompt_engine_workflow_run, class: "PromptEngine::WorkflowRun" do
    association :workflow, factory: :workflow
    initial_input { "Test input" }
    input_variables { {} }
    results { { final_output: "Test output", total_execution_time: 100 } }
    status { :completed }
    execution_time { 0.1 }
  end
end
