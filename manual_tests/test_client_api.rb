# Test to understand the exact client API
# Copy and paste this into Rails console

puts "=== Testing Client API ==="

# Test OpenAI client
if ENV["OPENAI_API_KEY"]
  begin
    require 'openai'
    client = OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])
    puts "OpenAI client created"
    
    # Test what methods exist and their signatures
    puts "OpenAI client methods:"
    puts client.methods.grep(/chat|completion|message/).sort
    
    # Try to understand the chat method
    puts "\nTesting OpenAI chat method:"
    begin
      # Try with minimal params
      result = client.chat
      puts "✓ client.chat() works (no params)"
    rescue => e
      puts "❌ client.chat() failed: #{e.message}"
    end
    
    begin
      # Try with parameters
      result = client.chat(parameters: {model: "gpt-3.5-turbo", messages: [{role: "user", content: "Hello"}]})
      puts "✓ client.chat(parameters: {...}) works"
    rescue => e
      puts "❌ client.chat(parameters: {...}) failed: #{e.message}"
    end
    
    begin
      # Try with splatted params
      result = client.chat(model: "gpt-3.5-turbo", messages: [{role: "user", content: "Hello"}])
      puts "✓ client.chat(model: ..., messages: ...) works"
    rescue => e
      puts "❌ client.chat(model: ..., messages: ...) failed: #{e.message}"
    end
    
  rescue => e
    puts "OpenAI test failed: #{e.message}"
  end
else
  puts "OpenAI API key not set"
end

# Test Anthropic client
if ENV["ANTHROPIC_API_KEY"]
  begin
    require 'anthropic'
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    puts "\nAnthropic client created"
    
    # Test what methods exist
    puts "Anthropic client methods:"
    puts client.methods.grep(/chat|completion|message/).sort
    
    # Test messages method
    puts "\nTesting Anthropic messages method:"
    begin
      result = client.messages
      puts "✓ client.messages works"
    rescue => e
      puts "❌ client.messages failed: #{e.message}"
    end
    
    begin
      result = client.messages.create(model: "claude-3-haiku-20240307", messages: [{role: "user", content: "Hello"}])
      puts "✓ client.messages.create(...) works"
    rescue => e
      puts "❌ client.messages.create(...) failed: #{e.message}"
    end
    
  rescue => e
    puts "Anthropic test failed: #{e.message}"
  end
else
  puts "Anthropic API key not set"
end

puts "\n=== API Test Complete ==="
