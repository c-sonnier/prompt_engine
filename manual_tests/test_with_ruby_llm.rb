# Alternative test using ruby_llm gem (if available)
# Copy and paste this into Rails console to test

puts "=== Testing execute_with with ruby_llm ==="

# Check if ruby_llm is available
begin
  require 'ruby_llm'
  ruby_llm_available = true
  puts "✓ ruby_llm gem is available"
rescue LoadError
  ruby_llm_available = false
  puts "⚠️  ruby_llm gem not found"
end

# Check for API keys
openai_key = ENV["OPENAI_API_KEY"]
anthropic_key = ENV["ANTHROPIC_API_KEY"]

# Create a test prompt
prompt = PromptEngine::Prompt.find_or_create_by(slug: "ruby-llm-test") do |p|
  p.name = "RubyLLM Test"
  p.content = "Say hello to {{name}}"
  p.system_message = "You are helpful."
  p.model = "gpt-3.5-turbo"
  p.temperature = 0.7
  p.max_tokens = 50
  p.status = "enabled"
  p.tools = []
end

# Render the prompt
rendered = prompt.render(name: "RubyLLM")

if ruby_llm_available
  # Test with OpenAI via ruby_llm
  if openai_key && !openai_key.empty?
    puts "\n=== Testing OpenAI via ruby_llm ==="
    begin
      # Try different possible client classes from ruby_llm
      if defined?(RubyLLM::OpenAI::Client)
        client = RubyLLM::OpenAI::Client.new(api_key: openai_key)
        puts "✓ Using RubyLLM::OpenAI::Client"
      elsif defined?(RubyLLM::Client)
        client = RubyLLM::Client.new(provider: :openai, api_key: openai_key)
        puts "✓ Using RubyLLM::Client with OpenAI provider"
      else
        puts "❌ Could not find OpenAI client in ruby_llm"
        next
      end
      
      response = rendered.execute_with(client)
      puts "✅ OpenAI via ruby_llm test successful!"
      puts "  Response: #{response}"
      
    rescue => e
      puts "❌ OpenAI via ruby_llm test failed: #{e.message}"
      puts "  Error class: #{e.class}"
    end
  else
    puts "OpenAI API key not set"
  end

  # Test with Anthropic via ruby_llm
  if anthropic_key && !anthropic_key.empty?
    puts "\n=== Testing Anthropic via ruby_llm ==="
    begin
      # Try different possible client classes from ruby_llm
      if defined?(RubyLLM::Anthropic::Client)
        client = RubyLLM::Anthropic::Client.new(api_key: anthropic_key)
        puts "✓ Using RubyLLM::Anthropic::Client"
      elsif defined?(RubyLLM::Client)
        client = RubyLLM::Client.new(provider: :anthropic, api_key: anthropic_key)
        puts "✓ Using RubyLLM::Client with Anthropic provider"
      else
        puts "❌ Could not find Anthropic client in ruby_llm"
        next
      end
      
      response = rendered.execute_with(client)
      puts "✅ Anthropic via ruby_llm test successful!"
      puts "  Response: #{response}"
      
    rescue => e
      puts "❌ Anthropic via ruby_llm test failed: #{e.message}"
      puts "  Error class: #{e.class}"
    end
  else
    puts "Anthropic API key not set"
  end
else
  puts "ruby_llm not available - install it or use the direct gem tests"
end

puts "\n=== Test complete ==="
