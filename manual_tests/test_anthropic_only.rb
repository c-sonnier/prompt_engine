# Test Anthropic client only
# Copy and paste this into Rails console

puts "=== Testing Anthropic Client Only ==="

# Check for Anthropic gem
begin
  require 'anthropic'
  anthropic_available = true
  puts "✓ Anthropic gem available"
rescue LoadError
  anthropic_available = false
  puts "❌ Anthropic gem not available"
end

# Check for API key
anthropic_key = ENV["ANTHROPIC_API_KEY"]
if anthropic_key && !anthropic_key.empty?
  puts "✓ Anthropic API key available"
else
  puts "❌ Anthropic API key not set"
end

if anthropic_available && anthropic_key
  # Create a test prompt
  prompt = PromptEngine::Prompt.find_or_create_by(slug: "anthropic-test") do |p|
    p.name = "Anthropic Test"
    p.content = "Say hello to {{name}}"
    p.system_message = "You are helpful."
    p.model = "claude-3-haiku-20240307"
    p.temperature = 0.7
    p.max_tokens = 100
    p.status = "enabled"
    p.tools = []
  end

  # Render the prompt
  rendered = prompt.render(name: "Anthropic")

  # Test Anthropic client
  begin
    client = Anthropic::Client.new(api_key: anthropic_key)
    puts "✓ Anthropic client created"
    
    # Test the execute_with method
    puts "Testing execute_with method..."
    response = rendered.execute_with(client)
    
    puts "✅ Anthropic test successful!"
    puts "Response: #{response}"
    
  rescue => e
    puts "❌ Anthropic test failed: #{e.message}"
    puts "Error class: #{e.class}"
  end
else
  puts "Skipping Anthropic test - gem or API key not available"
end

puts "\n=== Test Complete ==="
