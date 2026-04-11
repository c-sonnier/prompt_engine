require "prompt_engine/version"
require "prompt_engine/engine"
require "prompt_engine/rendered_prompt"
require "prompt_engine/errors"

module PromptEngine
  class << self
    # Render a prompt by slug with variables and options
    # @param slug [String] The slug of the prompt to render
    # @param variables [Hash] Variables to interpolate in the prompt (default: {})
    # @param options [Hash] Rendering options via keyword argument
    # @option options [String] :status The status to filter by (defaults to 'enabled')
    # @option options [String] :model Override the prompt's default model
    # @option options [Float] :temperature Override the prompt's default temperature
    # @option options [Integer] :max_tokens Override the prompt's default max_tokens
    # @option options [Integer] :version Render a specific version number
    def render(slug, variables = {}, options: {})
      # Set defaults for options
      options = {
        status: "enabled"
      }.merge(options)

      # If version is specified, we need to find the prompt without status filter
      # because we want to load any version regardless of the prompt's current status
      if options[:version]
        # Find prompt by slug only (no status filter)
        prompt = Prompt.find_by_slug!(slug)

        # Pass along the original status option for the RenderedPrompt
        render_options = options.merge(variables)
      else
        # Extract status from options for finding the prompt
        status = options.delete(:status)

        # Find the prompt with the appropriate status
        prompt = find(slug, status: status)

        # Merge options with variables (status is only for finding, not rendering)
        render_options = options.merge(variables)
      end

      prompt.render(**render_options)
    end

    # Find a prompt by slug with optional status filter
    # @param slug [String] The slug of the prompt
    # @param status [String] The status to filter by (defaults to 'enabled')
    def find(slug, status: "enabled")
      if status
        Prompt.where(slug: slug, status: status).first!
      else
        # If explicitly passed as nil, find any status
        Prompt.find_by_slug!(slug)
      end
    end

    # Alias for array-like access (defaults to enabled status)
    def [](slug)
      find(slug)
    end

    # Execute a workflow by name
    def workflow(name, variables = {})
      workflow = Workflow.find_by!(name: name)
      workflow.execute(variables)
    end

    # Execute a workflow with step details
    def workflow_with_steps(name, variables = {})
      workflow = Workflow.find_by!(name: name)
      workflow.execute_with_steps(variables)
    end

    # Execute a prompt by slug with parameters
    # @param slug [String] The slug of the prompt to execute
    # @param parameters [Hash] Parameters to pass to the prompt
    # @return [Hash] Execution result with response, execution_time, token_count, model, and provider
    def execute(slug, parameters = {})
      # Find the prompt by slug (defaults to enabled status)
      prompt = find(slug)
      
      # Determine provider based on the prompt's model
      provider = determine_provider(prompt.model)
      
      # Get API key for the provider
      api_key = get_api_key(provider)
      
      # Execute the prompt using PlaygroundExecutor
      executor = PlaygroundExecutor.new(
        prompt: prompt,
        provider: provider,
        api_key: api_key,
        parameters: parameters
      )
      
      executor.execute
    end

    # Check if HTTP Basic Auth should be used
    def use_http_basic_auth?
      http_basic_auth_enabled && http_basic_auth_name.present? && http_basic_auth_password.present?
    end

    private

    # Determine the provider based on the model name
    # @param model [String] The model name
    # @return [String] The provider name ("anthropic" or "openai")
    def determine_provider(model)
      return "anthropic" if model.blank? # Default to anthropic if no model specified
      
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

    # Get the API key for the specified provider
    # @param provider [String] The provider name
    # @return [String] The API key
    # @raise [ArgumentError] If no API key is configured for the provider
    def get_api_key(provider)
      settings = Setting.instance
      
      case provider
      when "anthropic"
        api_key = settings.anthropic_api_key
        raise ArgumentError, "Anthropic API key not configured. Please configure it in the settings." if api_key.blank?
        api_key
      when "openai"
        api_key = settings.openai_api_key
        raise ArgumentError, "OpenAI API key not configured. Please configure it in the settings." if api_key.blank?
        api_key
      else
        raise ArgumentError, "Unsupported provider: #{provider}"
      end
    end
  end
end
