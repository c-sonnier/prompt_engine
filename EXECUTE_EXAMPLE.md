# PromptEngine.execute Example

This example demonstrates how to use the new `PromptEngine.execute` method to easily execute prompts with a simple API.

## Setup

First, create a prompt in the admin interface or via code:

```ruby
# Create a customer support prompt
prompt = PromptEngine::Prompt.create!(
  name: "Customer Support Response",
  slug: "customer-support",
  content: "Hello {{customer_name}}, I understand you're having trouble with {{issue}}. Let me help you resolve this.",
  system_message: "You are a helpful customer support agent. Be professional and empathetic.",
  model: "gpt-3.5-turbo",
  temperature: 0.7,
  status: "enabled"
)
```

## Basic Usage

```ruby
# Execute the prompt with parameters
result = PromptEngine.execute("customer-support", 
  customer_name: "John", 
  issue: "Can't login to my account"
)

puts result[:response]
# => "Hello John, I understand you're having trouble with Can't login to my account. Let me help you resolve this."

puts result[:execution_time]  # => 1.234
puts result[:token_count]     # => 25
puts result[:model]          # => "gpt-3.5-turbo"
puts result[:provider]       # => "openai"
```

## Advanced Usage

```ruby
# Execute with different models (provider auto-detected)
claude_prompt = PromptEngine::Prompt.create!(
  name: "Email Writer",
  slug: "email-writer",
  content: "Write a professional email about {{topic}}",
  model: "claude-3-sonnet",
  temperature: 0.5,
  status: "enabled"
)

result = PromptEngine.execute("email-writer", topic: "project update")
puts result[:provider]  # => "anthropic" (auto-detected from claude-3-sonnet)
```

## Error Handling

```ruby
begin
  result = PromptEngine.execute("non-existent-prompt", name: "Test")
rescue ActiveRecord::RecordNotFound
  puts "Prompt not found"
end

begin
  result = PromptEngine.execute("customer-support", name: "Test")
rescue ArgumentError => e
  puts "API key not configured: #{e.message}"
end
```

## Key Benefits

1. **Simple API**: Just `PromptEngine.execute("slug", parameters)`
2. **Auto-detection**: Automatically detects provider based on model
3. **No database storage**: Unlike playground, results aren't saved
4. **Full functionality**: Supports all prompt features (tools, JSON mode, etc.)
5. **Error handling**: Clear error messages for common issues

## Requirements

- API keys must be configured in the settings
- Prompt must exist and be enabled
- Model must be supported by the configured provider
