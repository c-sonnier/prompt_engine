# Test OpenAI client with simple approach
# Copy and paste this into Rails console

puts "=== Testing OpenAI Client ==="

begin
  require 'openai'
  puts "✓ OpenAI gem available"
  
  if ENV["OPENAI_API_KEY"]
    client = OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])
    puts "✓ OpenAI client created"
    
    # Since client.chat() takes no parameters, let's see what we can do
    puts "Testing client.chat() with no parameters..."
    begin
      response = client.chat
      puts "✅ client.chat() worked!"
      puts "Response: #{response}"
    rescue => e
      puts "❌ client.chat() failed: #{e.message}"
    end
    
    # Try to see if there are any configuration methods
    puts "\nChecking for configuration methods..."
    if client.respond_to?(:model=)
      puts "✓ Has model= method"
      begin
        client.model = "gpt-3.5-turbo"
        puts "✓ Set model successfully"
      rescue => e
        puts "❌ Failed to set model: #{e.message}"
      end
    end
    
    if client.respond_to?(:messages=)
      puts "✓ Has messages= method"
    end
    
    if client.respond_to?(:temperature=)
      puts "✓ Has temperature= method"
    end
    
    # Try to see if we can call chat after setting parameters
    if client.respond_to?(:model=)
      begin
        client.model = "gpt-3.5-turbo"
        response = client.chat
        puts "✅ client.chat() after setting model worked!"
        puts "Response: #{response}"
      rescue => e
        puts "❌ client.chat() after setting model failed: #{e.message}"
      end
    end
    
  else
    puts "❌ OpenAI API key not set"
  end
  
rescue LoadError
  puts "❌ OpenAI gem not available"
end

puts "\n=== Test Complete ==="
