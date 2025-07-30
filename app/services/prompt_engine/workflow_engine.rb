module PromptEngine
  class WorkflowEngine
    def initialize(workflow)
      @workflow = workflow
    end

    def execute(initial_input: "", variables: {})
      # Keep the original variables throughout the workflow
      persistent_variables = variables.dup
      persistent_variables[:input] = initial_input

      @workflow.steps.keys.sort.each do |step_key|
        prompt_slug = @workflow.steps[step_key]
        output = PromptEngine.render(prompt_slug, **persistent_variables)

        # Update the input for the next step, but keep all other variables
        persistent_variables[:input] = output.content
        persistent_variables[:output] = output.content
      end

      persistent_variables[:output]
    end

    def execute_with_steps(initial_input: "", variables: {}, provider: nil, api_key: nil)
      current_variables = variables.dup
      current_variables[:input] = initial_input

      results = {
        steps: [],
        total_execution_time: 0
      }

      start_time = Time.current

      @workflow.steps.keys.sort.each_with_index do |step_key, index|
        prompt_slug = @workflow.steps[step_key]
        step_start_time = Time.current

        # For playground execution with provider/api_key, we need to use the playground executor
        if provider && api_key
          prompt = PromptEngine::Prompt.find_by(slug: prompt_slug)
          if prompt
            executor = PromptEngine::PlaygroundExecutor.new(
              prompt: prompt,
              provider: provider,
              api_key: api_key,
              parameters: current_variables
            )

            execution_result = executor.execute
            output_content = execution_result[:response]
            execution_time = execution_result[:execution_time]
          else
            output_content = "Error: Prompt '#{prompt_slug}' not found"
            execution_time = 0
          end
        else
          # Standard execution for API calls
          rendered_output = PromptEngine.render(prompt_slug, **current_variables)
          output_content = rendered_output.content
          execution_time = (Time.current - step_start_time) * 1000
        end

        step_result = {
          step: step_key,
          prompt_slug: prompt_slug,
          input: current_variables[:input],
          output: output_content,
          execution_time: execution_time
        }

        results[:steps] << step_result

        # After the first step, only pass the output to the next step
        if index == 0
          # First step: keep all variables but update input/output
          current_variables[:input] = output_content
          current_variables[:output] = output_content
        else
          # Subsequent steps: only pass input and output
          current_variables = {
            input: output_content,
            output: output_content
          }
        end
      end

      results[:final_output] = current_variables[:output]
      results[:total_execution_time] = (Time.current - start_time) * 1000
      results
    end
  end
end
