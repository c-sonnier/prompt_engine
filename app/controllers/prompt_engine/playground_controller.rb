module PromptEngine
  class PlaygroundController < ApplicationController
    before_action :set_prompt

    def show
      @parameters = ParameterParser.new(@prompt.content).extract_parameters.map { |p| p[:name] }
      @settings = Setting.instance
      @available_models = @settings.available_models
      @models_by_provider = @settings.models_by_provider
      
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
        parser = ParameterParser.new(@prompt.content)
        @rendered_prompt = parser.replace_parameters(params[:parameters])

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

    def process_parameters_with_files
      processed_params = params[:parameters]&.to_unsafe_h || {}

      # Collect all uploaded files, filtering out empty ones
      uploaded_files = []

      # Add files from the general file upload field
      if params[:files].present?
        general_files = params[:files].is_a?(Array) ? params[:files] : [ params[:files] ]
        uploaded_files.concat(general_files.compact.reject { |f| f.blank? || (f.respond_to?(:original_filename) && f.original_filename.blank?) })
      end

      # Add files to parameters if any were uploaded
      if uploaded_files.any?
        processed_params[:files] = uploaded_files
      end

      processed_params
    end

    def determine_provider_from_model(model)
      return nil if model.blank?
      
      model_lower = model.downcase
      
      # Check for Anthropic models
      if model_lower.include?("claude") || model_lower.include?("anthropic")
        "anthropic"
      # Check for OpenAI models
      elsif model_lower.include?("gpt") || model_lower.include?("openai") || model_lower.include?("davinci") || model_lower.include?("curie") || model_lower.include?("babbage") || model_lower.include?("ada")
        "openai"
      else
        # Default to anthropic for unknown models
        "anthropic"
      end
    end
  end
end
