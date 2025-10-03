class AddToolsToPrompts < ActiveRecord::Migration[8.0]
  def change
    add_column :prompt_engine_prompts, :tools, :json, null: false
    add_column :prompt_engine_prompt_versions, :tools, :json, null: false
    add_index :prompt_engine_prompts, :tools
    add_index :prompt_engine_prompt_versions, :tools
  end
end
