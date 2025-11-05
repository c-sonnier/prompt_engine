class AddDefaultArrayToPromptTools < ActiveRecord::Migration[8.0]
  def change
    change_column_default :prompt_engine_prompts, :tools, from: nil, to: []
    change_column_default :prompt_engine_prompt_versions, :tools, from: nil, to: []
  end
end
