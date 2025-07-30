FactoryBot.define do
  factory :workflow, class: "PromptEngine::Workflow" do
    sequence(:name) { |n| "workflow-#{n}" }
    steps { { "1" => "test-prompt" } }
    conditions { nil }

    trait :with_multiple_steps do
      steps { { "1" => "step-1", "2" => "step-2", "3" => "step-3" } }
    end

    trait :with_conditions do
      conditions { { "if" => "{{condition}} == 'true'" } }
    end
  end
end
