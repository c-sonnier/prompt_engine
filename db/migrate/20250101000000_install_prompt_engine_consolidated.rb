class InstallPromptEngineConsolidated < ActiveRecord::Migration[8.0]
  def up
    # Create prompt_engine_settings table
    create_table :prompt_engine_settings, if_not_exists: true do |t|
      # Encrypted API keys
      t.text :openai_api_key
      t.text :anthropic_api_key
      # Other settings can be added here in the future
      t.json :preferences
      t.timestamps
    end

    # Create prompt_engine_prompts table
    create_table :prompt_engine_prompts, if_not_exists: true do |t|
      t.string :name
      t.text :description
      t.text :content
      t.text :system_message
      t.string :model
      t.float :temperature
      t.integer :max_tokens
      t.string :status
      t.json :metadata
      t.integer :versions_count, default: 0, null: false
      t.string :slug
      t.timestamps
    end

    add_index :prompt_engine_prompts, :slug, unique: true unless index_exists?(:prompt_engine_prompts, :slug)

    # Add json_mode column to prompts if it doesn't exist
    add_column :prompt_engine_prompts, :json_mode, :boolean, default: false, null: false unless column_exists?(:prompt_engine_prompts, :json_mode)
    add_index :prompt_engine_prompts, :json_mode unless index_exists?(:prompt_engine_prompts, :json_mode)

    # Add tools column to prompts if it doesn't exist
    add_column :prompt_engine_prompts, :tools, :json, null: false unless column_exists?(:prompt_engine_prompts, :tools)
    add_index :prompt_engine_prompts, :tools unless index_exists?(:prompt_engine_prompts, :tools)

    # Create prompt_engine_parameters table
    create_table :prompt_engine_parameters, if_not_exists: true do |t|
      t.references :prompt, null: false, foreign_key: {to_table: :prompt_engine_prompts}
      t.string :name, null: false
      t.text :description
      t.string :parameter_type, null: false, default: "string"
      t.boolean :required, null: false, default: true
      t.string :default_value
      t.json :validation_rules
      t.string :example_value
      t.integer :position
      t.timestamps
    end

    add_index :prompt_engine_parameters, [:prompt_id, :name], unique: true unless index_exists?(:prompt_engine_parameters, [:prompt_id, :name])
    add_index :prompt_engine_parameters, :position unless index_exists?(:prompt_engine_parameters, :position)

    # Create prompt_engine_prompt_versions table
    create_table :prompt_engine_prompt_versions, if_not_exists: true do |t|
      t.references :prompt, null: false, foreign_key: {to_table: :prompt_engine_prompts}
      t.integer :version_number, null: false
      t.text :content, null: false
      t.text :system_message
      t.string :model
      t.float :temperature
      t.integer :max_tokens
      t.json :metadata
      t.string :created_by
      t.text :change_description
      t.timestamps
    end

    add_index :prompt_engine_prompt_versions, [:prompt_id, :version_number], unique: true, name: "index_prompt_versions_on_prompt_and_version" unless index_exists?(:prompt_engine_prompt_versions, [:prompt_id, :version_number])
    add_index :prompt_engine_prompt_versions, :version_number unless index_exists?(:prompt_engine_prompt_versions, :version_number)

    # Add json_mode column to prompt_versions if it doesn't exist
    add_column :prompt_engine_prompt_versions, :json_mode, :boolean, default: false, null: false unless column_exists?(:prompt_engine_prompt_versions, :json_mode)
    add_index :prompt_engine_prompt_versions, :json_mode unless index_exists?(:prompt_engine_prompt_versions, :json_mode)

    # Add active column to prompt_versions if it doesn't exist
    add_column :prompt_engine_prompt_versions, :active, :boolean, default: false, null: false unless column_exists?(:prompt_engine_prompt_versions, :active)
    add_index :prompt_engine_prompt_versions, :active unless index_exists?(:prompt_engine_prompt_versions, :active)

    # Add tools column to prompt_versions if it doesn't exist
    add_column :prompt_engine_prompt_versions, :tools, :json, null: false unless column_exists?(:prompt_engine_prompt_versions, :tools)
    add_index :prompt_engine_prompt_versions, :tools unless index_exists?(:prompt_engine_prompt_versions, :tools)

    # Create prompt_engine_playground_run_results table
    create_table :prompt_engine_playground_run_results, if_not_exists: true do |t|
      t.references :prompt_version, null: false, foreign_key: {to_table: :prompt_engine_prompt_versions}
      # API Provider and Model Info
      t.string :provider, null: false
      t.string :model, null: false
      # Prompt Details
      t.text :rendered_prompt, null: false
      t.text :system_message
      t.text :parameters
      # Response Details
      t.text :response, null: false
      t.float :execution_time, null: false
      t.integer :token_count
      # Settings Used
      t.float :temperature
      t.integer :max_tokens
      t.timestamps
    end

    add_index :prompt_engine_playground_run_results, :provider unless index_exists?(:prompt_engine_playground_run_results, :provider)
    add_index :prompt_engine_playground_run_results, :created_at unless index_exists?(:prompt_engine_playground_run_results, :created_at)

    # Create prompt_engine_eval_sets table
    create_table :prompt_engine_eval_sets, if_not_exists: true do |t|
      t.string :name, null: false
      t.text :description
      t.references :prompt, null: false, foreign_key: {to_table: :prompt_engine_prompts}
      t.string :openai_eval_id
      t.string :grader_type, default: "exact_match", null: false
      t.json :grader_config
      t.timestamps
    end

    add_index :prompt_engine_eval_sets, :openai_eval_id unless index_exists?(:prompt_engine_eval_sets, :openai_eval_id)
    add_index :prompt_engine_eval_sets, :grader_type unless index_exists?(:prompt_engine_eval_sets, :grader_type)
    add_index :prompt_engine_eval_sets, [:prompt_id, :name], unique: true unless index_exists?(:prompt_engine_eval_sets, [:prompt_id, :name])

    # Create prompt_engine_test_cases table
    create_table :prompt_engine_test_cases, if_not_exists: true do |t|
      t.references :eval_set, null: false, foreign_key: {to_table: :prompt_engine_eval_sets}
      t.json :input_variables, null: false
      t.text :expected_output, null: false
      t.text :description
      t.timestamps
    end

    # Create prompt_engine_eval_runs table
    create_table :prompt_engine_eval_runs, if_not_exists: true do |t|
      t.references :eval_set, null: false, foreign_key: {to_table: :prompt_engine_eval_sets}
      t.references :prompt_version, null: false, foreign_key: {to_table: :prompt_engine_prompt_versions}
      t.integer :status, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :total_count, default: 0
      t.integer :passed_count, default: 0
      t.integer :failed_count, default: 0
      t.text :error_message
      t.string :openai_run_id
      t.string :openai_file_id
      t.string :report_url
      t.timestamps
    end

    add_index :prompt_engine_eval_runs, :openai_run_id unless index_exists?(:prompt_engine_eval_runs, :openai_run_id)

    # Create prompt_engine_eval_results table
    create_table :prompt_engine_eval_results, if_not_exists: true do |t|
      t.references :eval_run, null: false, foreign_key: {to_table: :prompt_engine_eval_runs}
      t.references :test_case, null: false, foreign_key: {to_table: :prompt_engine_test_cases}
      t.text :actual_output
      t.boolean :passed, default: false
      t.integer :execution_time_ms
      t.text :error_message
      t.timestamps
    end

    # Create prompt_engine_workflows table
    create_table :prompt_engine_workflows, if_not_exists: true do |t|
      t.string :name, null: false, index: { unique: true }
      t.json :steps, null: false
      t.json :conditions, default: nil
      t.timestamps
    end

    # Add pass_original_input column to workflows if it doesn't exist
    add_column :prompt_engine_workflows, :pass_original_input, :boolean, default: true, null: false unless column_exists?(:prompt_engine_workflows, :pass_original_input)

    # Create prompt_engine_workflow_runs table
    create_table :prompt_engine_workflow_runs, if_not_exists: true do |t|
      t.references :workflow, null: false, foreign_key: { to_table: :prompt_engine_workflows }
      t.text :initial_input
      t.json :input_variables
      t.json :results
      t.integer :status, default: 0, null: false
      t.decimal :execution_time, precision: 8, scale: 3
      t.text :error_message
      
      t.timestamps
    end
    
    add_index :prompt_engine_workflow_runs, :status unless index_exists?(:prompt_engine_workflow_runs, :status)
    add_index :prompt_engine_workflow_runs, :created_at unless index_exists?(:prompt_engine_workflow_runs, :created_at)

    # Add title column to workflow_runs if it doesn't exist
    add_column :prompt_engine_workflow_runs, :title, :string unless column_exists?(:prompt_engine_workflow_runs, :title)
    
  end

  def down
    # Drop tables in reverse order to respect foreign key constraints
    drop_table :prompt_engine_workflow_runs if table_exists?(:prompt_engine_workflow_runs)
    drop_table :prompt_engine_workflows if table_exists?(:prompt_engine_workflows)
    drop_table :prompt_engine_eval_results if table_exists?(:prompt_engine_eval_results)
    drop_table :prompt_engine_eval_runs if table_exists?(:prompt_engine_eval_runs)
    drop_table :prompt_engine_test_cases if table_exists?(:prompt_engine_test_cases)
    drop_table :prompt_engine_eval_sets if table_exists?(:prompt_engine_eval_sets)
    drop_table :prompt_engine_playground_run_results if table_exists?(:prompt_engine_playground_run_results)
    drop_table :prompt_engine_prompt_versions if table_exists?(:prompt_engine_prompt_versions)
    drop_table :prompt_engine_parameters if table_exists?(:prompt_engine_parameters)
    drop_table :prompt_engine_prompts if table_exists?(:prompt_engine_prompts)
    drop_table :prompt_engine_settings if table_exists?(:prompt_engine_settings)
  end
end
