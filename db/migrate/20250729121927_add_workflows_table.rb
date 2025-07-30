class AddWorkflowsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :prompt_engine_workflows do |t|
      t.string :name, null: false, index: { unique: true }
      t.json :steps, null: false
      t.json :conditions, default: nil
      t.timestamps
    end
  end
end
