module PromptEngine
  class PlaygroundController < ApplicationController
    include ModelConfigurationConcern
    include ParameterProcessingConcern
    
    before_action :set_prompt

    def show
      @parameters = PromptEngine::VariableDetector.new(@prompt.content).variable_names
      load_model_configuration
      
      # Determine provider and model from prompt configuration
      @provider = determine_provider_from_model(@prompt.model)
      @model_info = @settings.find_model_by_value(@prompt.model) if @prompt.model.present?
      
      # If no model is configured, use default for the determined provider
      if @prompt.model.blank? && @provider
        @prompt.model = @settings.default_model_for_provider(@provider)
        @model_info = @settings.find_model_by_value(@prompt.model)
      end
    end

    def execute
      # Process uploaded files and add them to parameters
      processed_parameters = process_parameters_with_files

      # Validate API key is present and not empty
      if params[:api_key].blank?
        @error = "API key is required"
        render :result and return
      end

      # Determine provider from prompt configuration (same logic as in show)
      provider = determine_provider_from_model(@prompt.model)
      if provider.blank?
        @error = "Unable to determine AI provider from prompt model configuration"
        render :result and return
      end

      executor = PlaygroundExecutor.new(
        prompt: @prompt,
        provider: provider,
        api_key: params[:api_key].strip,
        parameters: processed_parameters
      )

      begin
        result = executor.execute
        @response = result[:response]
        @execution_time = result[:execution_time]
        @token_count = result[:token_count]
        @model = result[:model]
        @provider = result[:provider]

        # Store the rendered prompt for display
        detector = PromptEngine::VariableDetector.new(@prompt.content)
        @rendered_prompt = detector.render(params[:parameters])

        # Save the playground run result
        @prompt.current_version.playground_run_results.create!(
          provider: @provider,
          model: @model,
          rendered_prompt: @rendered_prompt,
          system_message: @prompt.system_message,
          parameters: params[:parameters],
          response: @response,
          execution_time: @execution_time,
          token_count: @token_count,
          temperature: @prompt.temperature,
          max_tokens: @prompt.max_tokens
        )
      rescue => e
        @error = e.message
      end

      render :result
    end

    private

    def set_prompt
      @prompt = Prompt.find(params[:id])
    end


    def determine_provider_from_model(model)
      PromptEngine::ProviderDetectionService.from_model_name(model) || "anthropic"
    end
  end
end
