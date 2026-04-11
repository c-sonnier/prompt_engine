# Debug script to check client initialization and available methods
# Copy and paste this into Rails console

puts "=== Debugging Client Initialization ==="

# Check OpenAI client
puts "\n--- OpenAI Client Debug ---"
begin
  require 'openai'
  puts "✓ OpenAI gem loaded"
  
  # Try different initialization methods
  puts "Trying OpenAI::Client.new()..."
  begin
    client = OpenAI::Client.new()
    puts "✓ OpenAI::Client.new() works"
  rescue => e
    puts "❌ OpenAI::Client.new() failed: #{e.message}"
  end
  
  puts "Trying OpenAI::Client.new(api_key: 'test')..."
  begin
    client = OpenAI::Client.new(api_key: 'test')
    puts "✓ OpenAI::Client.new(api_key: 'test') works"
  rescue => e
    puts "❌ OpenAI::Client.new(api_key: 'test') failed: #{e.message}"
  end
  
  # Check available methods
  if defined?(client)
    puts "Available methods on OpenAI client:"
    puts client.methods.grep(/chat|message|completion/).sort
  end
  
rescue LoadError
  puts "❌ OpenAI gem not available"
end

# Check Anthropic client
puts "\n--- Anthropic Client Debug ---"
begin
  require 'anthropic'
  puts "✓ Anthropic gem loaded"
  
  # Try different initialization methods
  puts "Trying Anthropic::Client.new()..."
  begin
    client = Anthropic::Client.new()
    puts "✓ Anthropic::Client.new() works"
  rescue => e
    puts "❌ Anthropic::Client.new() failed: #{e.message}"
  end
  
  puts "Trying Anthropic::Client.new(api_key: 'test')..."
  begin
    client = Anthropic::Client.new(api_key: 'test')
    puts "✓ Anthropic::Client.new(api_key: 'test') works"
  rescue => e
    puts "❌ Anthropic::Client.new(api_key: 'test') failed: #{e.message}"
  end
  
  # Check available methods
  if defined?(client)
    puts "Available methods on Anthropic client:"
    puts client.methods.grep(/chat|message|completion/).sort
  end
  
rescue LoadError
  puts "❌ Anthropic gem not available"
end

puts "\n=== Debug Complete ==="
