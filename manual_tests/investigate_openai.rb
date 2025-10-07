# Investigate OpenAI client API
# Copy and paste this into Rails console

puts "=== Investigating OpenAI Client API ==="

begin
  require 'openai'
  puts "✓ OpenAI gem loaded"
  
  # Check the gem version
  if defined?(OpenAI::VERSION)
    puts "OpenAI gem version: #{OpenAI::VERSION}"
  end
  
  # Check what the client class looks like
  puts "OpenAI::Client class: #{OpenAI::Client}"
  puts "OpenAI::Client methods: #{OpenAI::Client.instance_methods.grep(/chat|completion/)}"
  
  # Try to create a client
  if ENV["OPENAI_API_KEY"]
    client = OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])
    puts "✓ Client created successfully"
    
    # Check what methods the instance has
    puts "Client instance methods:"
    puts client.methods.grep(/chat|completion|message/).sort
    
    # Try to understand how to use it
    puts "\nTrying to understand the API..."
    
    # Check if there are any configuration methods
    if client.respond_to?(:configure)
      puts "Client has configure method"
    end
    
    # Check if there are any parameter setting methods
    if client.respond_to?(:model=)
      puts "Client has model= method"
    end
    
    # Try to see if we can set parameters on the client
    begin
      client.model = "gpt-3.5-turbo"
      puts "✓ Can set model on client"
    rescue => e
      puts "❌ Cannot set model on client: #{e.message}"
    end
    
    # Try to see if there are any other methods
    puts "\nAll client methods:"
    puts client.methods.sort
    
  else
    puts "OpenAI API key not set"
  end
  
rescue LoadError
  puts "❌ OpenAI gem not available"
rescue => e
  puts "❌ Error: #{e.message}"
end

puts "\n=== Investigation Complete ==="
