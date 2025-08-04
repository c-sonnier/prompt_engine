class CreatePromptEngineWorkflowRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :prompt_engine_workflow_runs do |t|
      t.references :workflow, null: false, foreign_key: { to_table: :prompt_engine_workflows }
      t.text :initial_input
      t.json :input_variables
      t.json :results
      t.integer :status, default: 0, null: false
      t.decimal :execution_time, precision: 8, scale: 3
      t.text :error_message
      
      t.timestamps
    end
    
    add_index :prompt_engine_workflow_runs, :status
    add_index :prompt_engine_workflow_runs, :created_at
  end
end
