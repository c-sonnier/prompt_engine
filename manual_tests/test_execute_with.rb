#!/usr/bin/env ruby
# Test file for execute_with method with OpenAI and Anthropic clients
# Copy and paste this into Rails console to test

puts "=== PromptEngine execute_with Test ==="
puts "This test will verify that the execute_with method works with both OpenAI and Anthropic clients"
puts

# Check if we're in a Rails environment
unless defined?(Rails) && Rails.env
  puts "❌ This test must be run in a Rails console"
  exit 1
end

# Check for required gems
puts "Checking for required gems..."
openai_gem_available = false
anthropic_gem_available = false

begin
  require 'openai'
  openai_gem_available = true
  puts "✓ OpenAI gem is available"
rescue LoadError
  puts "⚠️  OpenAI gem not found - add 'gem \"openai\"' to your Gemfile"
end

begin
  require 'anthropic'
  anthropic_gem_available = true
  puts "✓ Anthropic gem is available"
rescue LoadError
  puts "⚠️  Anthropic gem not found - add 'gem \"anthropic\"' to your Gemfile"
end

# Check for required environment variables
puts "\nChecking environment variables..."
openai_key = ENV["OPENAI_API_KEY"]
anthropic_key = ENV["ANTHROPIC_API_KEY"]

if openai_key.nil? || openai_key.empty?
  puts "⚠️  OPENAI_API_KEY not set - OpenAI tests will be skipped"
end

if anthropic_key.nil? || anthropic_key.empty?
  puts "⚠️  ANTHROPIC_API_KEY not set - Anthropic tests will be skipped"
end

puts

# Create a test prompt if it doesn't exist
puts "Setting up test prompt..."
test_prompt = PromptEngine::Prompt.find_or_create_by(slug: "test-execute-with") do |p|
  p.name = "Test Execute With"
  p.description = "Test prompt for execute_with method"
  p.content = "Hello! Please respond with a simple greeting. My name is {{name}} and I'm testing the execute_with method."
  p.system_message = "You are a helpful assistant. Keep responses brief and friendly."
  p.model = "gpt-3.5-turbo"  # This will be overridden per client
  p.temperature = 0.7
  p.max_tokens = 100
  p.status = "enabled"
  p.tools = []
end

puts "✓ Test prompt created/found: #{test_prompt.name}"

# Render the prompt
puts "\nRendering prompt with test parameters..."
rendered = test_prompt.render(name: "TestUser")
puts "✓ Prompt rendered successfully"
puts "  Content: #{rendered.content[0..50]}..."
puts "  Model: #{rendered.model}"
puts "  Temperature: #{rendered.temperature}"
puts "  Max Tokens: #{rendered.max_tokens}"

# Test 1: OpenAI Client
if openai_key && !openai_key.empty? && openai_gem_available
  puts "\n=== Testing OpenAI Client ==="
  begin
    # Try different initialization methods
    client = nil
    begin
      client = OpenAI::Client.new(api_key: openai_key)
      puts "✓ OpenAI client created with api_key parameter"
    rescue => e
      puts "Trying OpenAI::Client.new() without parameters..."
      client = OpenAI::Client.new()
      puts "✓ OpenAI client created without parameters"
    end
    
    puts "Testing execute_with method..."
    response = rendered.execute_with(client)
    
    puts "✅ OpenAI test successful!"
    puts "  Response: #{response}"
    puts "  Response class: #{response.class}"
    puts "  Response methods: #{response.methods.grep(/content|message|choice/).sort}"
    
  rescue => e
    puts "❌ OpenAI test failed: #{e.message}"
    puts "  Error class: #{e.class}"
    puts "  Available methods: #{client.methods.grep(/chat|message|completion/).sort}" if client
  end
elsif !openai_gem_available
  puts "\n=== Skipping OpenAI Test (gem not available) ==="
  puts "To enable OpenAI testing, add 'gem \"openai\"' to your Gemfile and run 'bundle install'"
elsif !openai_key || openai_key.empty?
  puts "\n=== Skipping OpenAI Test (no API key) ==="
end

# Test 2: Anthropic Client
if anthropic_key && !anthropic_key.empty? && anthropic_gem_available
  puts "\n=== Testing Anthropic Client ==="
  begin
    # Try different initialization methods
    client = nil
    begin
      client = Anthropic::Client.new(api_key: anthropic_key)
      puts "✓ Anthropic client created with api_key parameter"
    rescue => e
      puts "Trying Anthropic::Client.new() without parameters..."
      client = Anthropic::Client.new()
      puts "✓ Anthropic client created without parameters"
    end
    
    # Override the model for Anthropic
    rendered_with_anthropic_model = test_prompt.render(name: "TestUser", model: "claude-3-haiku-20240307")
    puts "Testing execute_with method with Anthropic model..."
    response = rendered_with_anthropic_model.execute_with(client)
    
    puts "✅ Anthropic test successful!"
    puts "  Response: #{response.content}"
    puts "  Model used: #{response.model}"
    puts "  Usage: #{response.usage}"
    
  rescue => e
    puts "❌ Anthropic test failed: #{e.message}"
    puts "  Error class: #{e.class}"
    puts "  Available methods: #{client.methods.grep(/chat|message|completion/).sort}" if client
  end
elsif !anthropic_gem_available
  puts "\n=== Skipping Anthropic Test (gem not available) ==="
  puts "To enable Anthropic testing, add 'gem \"anthropic\"' to your Gemfile and run 'bundle install'"
elsif !anthropic_key || anthropic_key.empty?
  puts "\n=== Skipping Anthropic Test (no API key) ==="
end

# Test 3: Test parameter methods
puts "\n=== Testing Parameter Methods ==="
puts "Testing to_openai_params method..."
openai_params = rendered.to_openai_params
puts "✓ OpenAI params generated:"
puts "  Model: #{openai_params[:model]}"
puts "  Messages count: #{openai_params[:messages].length}"
puts "  Temperature: #{openai_params[:temperature]}"
puts "  Max tokens: #{openai_params[:max_tokens]}"

puts "\nTesting to_ruby_llm_params method..."
ruby_llm_params = rendered.to_ruby_llm_params
puts "✓ RubyLLM params generated:"
puts "  Model: #{ruby_llm_params[:model]}"
puts "  Messages count: #{ruby_llm_params[:messages].length}"
puts "  Temperature: #{ruby_llm_params[:temperature]}"
puts "  Max tokens: #{ruby_llm_params[:max_tokens]}"

# Test 4: Test with additional options
puts "\n=== Testing with Additional Options ==="
if openai_key && !openai_key.empty? && openai_gem_available
  begin
    client = OpenAI::Client.new(api_key: openai_key)
    
    puts "Testing with additional options (stream: true)..."
    response = rendered.execute_with(client, stream: true)
    puts "✅ Additional options test successful!"
    
  rescue => e
    puts "❌ Additional options test failed: #{e.message}"
  end
else
  puts "Skipping additional options test (OpenAI gem or API key not available)"
end

puts "\n=== Test Summary ==="
puts "All tests completed. Check the results above for any failures."
puts "If you see ✅ marks, the execute_with method is working correctly!"
puts "If you see ❌ marks, there may be configuration issues to resolve."
