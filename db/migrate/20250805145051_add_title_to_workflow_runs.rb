class AddTitleToWorkflowRuns < ActiveRecord::Migration[8.0]
  def up
    add_column :prompt_engine_workflow_runs, :title, :string
    
    # Backfill existing records
    PromptEngine::WorkflowRun.find_each do |run|
      run.update_column(:title, run.created_at.strftime("%B %d, %Y at %I:%M %p"))
    end
  end
  
  def down
    remove_column :prompt_engine_workflow_runs, :title
  end
end
