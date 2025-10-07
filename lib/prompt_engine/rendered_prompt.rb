module PromptEngine
  class RenderedPrompt
    attr_reader :prompt, :content, :overrides,
                :version_number

    def initialize(prompt, rendered_data, overrides = {})
      @prompt = prompt
      @content = rendered_data[:content]
      @parameters = rendered_data[:parameters_used] || {}
      @overrides = overrides
      @version_number = rendered_data[:version_number]
      @rendered_data = rendered_data

      # Store status - use override if provided, otherwise use prompt's current status
      # Note: When a specific version is loaded, we still use the current prompt status
      # unless explicitly overridden
      @status = overrides.key?(:status) ? overrides[:status] : prompt.status
    end

    # Options accessor - returns the options hash used for rendering
    def options
      @overrides.dup
    end

    # Individual accessors for common options
    def status
      @status
    end

    def version
      @version_number
    end

    def model
      @overrides[:model] || @rendered_data[:model]
    end

    def temperature
      @overrides[:temperature] || @rendered_data[:temperature]
    end

    def max_tokens
      @overrides[:max_tokens] || @rendered_data[:max_tokens]
    end

    def json_mode
      @overrides.key?(:json_mode) ? @overrides[:json_mode] : @rendered_data[:json_mode] || prompt.json_mode
    end

    def system_message
      @overrides[:system_message] || @rendered_data[:system_message]
    end

    # Returns messages array for chat-based models
    def messages
      msgs = []
      msgs << { role: "system", content: system_message } if system_message.present?
      
      # Ensure JSON instruction is present when json_mode is enabled
      user_content = content
      if json_mode && !user_content.downcase.include?('json')
        user_content = "#{user_content}\n\nPlease respond with valid JSON format."
      end
      
      msgs << { role: "user", content: user_content }
      msgs
    end

    # For OpenAI gem compatibility
    def to_openai_params(**additional_options)
      base_params = {
        model: model || "gpt-4",
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens
      }.compact

      # Merge with additional options (tools, functions, response_format, etc.)
      base_params.merge(additional_options)
    end

    # For RubyLLM compatibility
    def to_ruby_llm_params(**additional_options)
      # For Anthropic, we need to separate system message from user messages
      user_messages = []
      user_messages << { role: "user", content: content }
      
      base_params = {
        messages: user_messages,
        model: model || "gpt-4",
        temperature: temperature,
        max_tokens: max_tokens
      }.compact
      
      # Add system message as top-level parameter for Anthropic
      if system_message.present?
        base_params[:system] = system_message
      end

      # If json_mode enabled and no explicit response_format passed, add it
      if json_mode && !additional_options.key?(:response_format)
        additional_options = additional_options.merge(response_format: { type: "json_object" })
      end

      base_params.merge(additional_options)
    end

    # Automatic client detection and execution
    def execute_with(client, **options)
      case client.class.name
      when /OpenAI/
        execute_with_openai(client, **options)
      when /Anthropic/
        execute_with_anthropic(client, **options)
      when /RubyLLM/
        execute_with_ruby_llm(client, **options)
      else
        raise ArgumentError, "Unknown client type: #{client.class.name}"
      end
    end

    private

    # Execute with OpenAI client
    def execute_with_openai(client, **options)
      # OpenAI client.chat() takes no parameters - it's a different API
      # Try to configure the client first, then call chat
      params = to_openai_params(**options)
      
      begin
        # Try to set parameters on the client if possible
        if client.respond_to?(:model=)
          client.model = params[:model] if params[:model]
        end
        
        if client.respond_to?(:messages=)
          client.messages = params[:messages] if params[:messages]
        end
        
        if client.respond_to?(:temperature=)
          client.temperature = params[:temperature] if params[:temperature]
        end
        
        if client.respond_to?(:max_tokens=)
          client.max_tokens = params[:max_tokens] if params[:max_tokens]
        end
        
        # Now try to call chat
        client.chat
      rescue => e
        raise NotImplementedError, "OpenAI client API is different than expected. The client.chat() method takes no parameters. Error: #{e.message}. You may need to use a different OpenAI gem version or configure the client differently."
      end
    end

    # Execute with Anthropic client
    def execute_with_anthropic(client, **options)
      params = to_ruby_llm_params(**options)
      # Ensure max_tokens is present for Anthropic
      params[:max_tokens] ||= 1000
      
      begin
        if client.respond_to?(:messages) && client.messages.respond_to?(:create)
          client.messages.create(**params)
        elsif client.respond_to?(:messages)
          client.messages(**params)
        else
          raise ArgumentError, "Anthropic client does not have expected methods"
        end
      rescue => e
        raise ArgumentError, "Failed to call Anthropic client: #{e.message}"
      end
    end

    # Execute with RubyLLM client
    def execute_with_ruby_llm(client, **options)
      params = to_ruby_llm_params(**options)
      
      begin
        if client.respond_to?(:messages) && client.messages.respond_to?(:create)
          client.messages.create(**params)
        elsif client.respond_to?(:messages)
          client.messages(**params)
        elsif client.respond_to?(:completions)
          client.completions(**params)
        else
          client.chat(**params)
        end
      rescue => e
        raise ArgumentError, "Failed to call RubyLLM client: #{e.message}"
      end
    end

    # Parameter access methods
    def parameters
      @parameters
    end

    def parameter(key)
      @parameters[key.to_s]
    end

    def parameter_names
      @parameters.keys
    end

    def parameter_values
      @parameters.values
    end

    # Check if a parameter exists
    def parameter?(key)
      @parameters.key?(key.to_s)
    end

    # Convenience methods
    def to_h
      {
        content: content,
        system_message: system_message,
        model: model,
        temperature: temperature,
        max_tokens: max_tokens,
        messages: messages,
        options: options,
        status: status,
        version: version,
        parameters: parameters
      }
    end

    def inspect
      version_info = version_number ? " version=#{version_number}" : ""
      param_info = parameter_names.any? ? " parameters=#{parameter_names}" : ""
      override_info = overrides.any? ? " overrides=#{overrides.keys}" : ""
      "#<PromptEngine::RenderedPrompt prompt=#{prompt.slug}#{version_info}#{param_info}#{override_info}>"
    end
  end
end
