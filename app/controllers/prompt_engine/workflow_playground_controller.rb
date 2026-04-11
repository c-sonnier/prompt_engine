module PromptEngine
  class WorkflowPlaygroundController < ApplicationController
    include ModelConfigurationConcern
    include ParameterProcessingConcern
    
    layout "prompt_engine/admin"
    before_action :set_workflow

    def show
      load_model_configuration
      # Get unique parameters from all prompts in the workflow
      @parameters = extract_workflow_parameters
      # Get the first prompt for parameter type checking
      @first_prompt = get_first_prompt
      # Check if the first prompt needs text input
      @needs_text_input = first_prompt_needs_text_input?
    end

    def execute
      # Validate API key is present and not empty
      if params[:api_key].blank?
        @error = "API key is required"
        render :result and return
      end

      # Process uploaded files and add them to parameters
      processed_parameters = process_parameters_with_files

      begin
        # Execute the workflow
        workflow_engine = PromptEngine::WorkflowEngine.new(@workflow)

        # For playground execution, we'll use the detailed execution method
        # so we can see the output of each step
        result = workflow_engine.execute_with_steps(
          initial_input: processed_parameters[:initial_input] || "",
          variables: processed_parameters.except(:initial_input),
          provider: params[:provider],
          api_key: params[:api_key].strip,
          save_run: true  # Always save playground executions
        )

        @workflow_result = result
        @execution_time = result[:total_execution_time]
        @provider = params[:provider]

        # Store the workflow execution for tracking
        # TODO: Create a WorkflowRunResult model similar to PlaygroundRunResult
        # for now we'll just display the results

      rescue => e
        @error = e.message
      end

      render :result
    end

    private

    def set_workflow
      @workflow = PromptEngine::Workflow.find(params[:id])
    end

    def extract_workflow_parameters
      return [] unless @workflow.steps.present?

      # Get the first step in the workflow
      first_step_key = @workflow.steps.keys.sort.first
      return [] unless first_step_key

      first_prompt_slug = @workflow.steps[first_step_key]

      begin
        prompt = PromptEngine::Prompt.find_by(slug: first_prompt_slug)
        return [] unless prompt

        # Extract parameters from only the first prompt's content
        detector = PromptEngine::VariableDetector.new(prompt.content)
        prompt_params = detector.variable_names

        # Filter out 'input' since we handle that separately as initial_input
        prompt_params.reject { |param| param.downcase == "input" }
      rescue => e
        # Return empty array if prompt not found or other error
        []
      end
    end

    def get_first_prompt
      return nil unless @workflow.steps.present?

      first_step_key = @workflow.steps.keys.sort.first
      return nil unless first_step_key

      first_prompt_slug = @workflow.steps[first_step_key]
      PromptEngine::Prompt.find_by(slug: first_prompt_slug)
    end

    def first_prompt_needs_text_input?
      return false unless @workflow.steps.present?

      # Get the first step in the workflow
      first_step_key = @workflow.steps.keys.sort.first
      return false unless first_step_key

      first_prompt_slug = @workflow.steps[first_step_key]

      begin
        prompt = PromptEngine::Prompt.find_by(slug: first_prompt_slug)
        return false unless prompt

        # Extract parameters from the first prompt's content
        detector = PromptEngine::VariableDetector.new(prompt.content)
        prompt_params = detector.variable_names

        # Check if it has an 'input' parameter and no file-related parameters
        has_input = prompt_params.include?("input")
        file_related_params = [ "files", "file", "pdf", "document", "image", "attachment" ]
        has_file_params = prompt_params.any? { |param| file_related_params.include?(param.downcase) }

        # Only show text input if it has 'input' parameter but no file parameters
        has_input && !has_file_params
      rescue => e
        false
      end
    end

  end
end
