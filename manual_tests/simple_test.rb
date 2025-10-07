# Simple test for execute_with method - copy and paste into Rails console

# Check for required gems first
puts "Checking for required gems..."
begin
  require 'openai'
  openai_available = true
  puts "✓ OpenAI gem available"
rescue LoadError
  openai_available = false
  puts "⚠️  OpenAI gem not found - add 'gem \"openai\"' to your Gemfile"
end

begin
  require 'anthropic'
  anthropic_available = true
  puts "✓ Anthropic gem available"
rescue LoadError
  anthropic_available = false
  puts "⚠️  Anthropic gem not found - add 'gem \"anthropic\"' to your Gemfile"
end

# 1. Create a test prompt
prompt = PromptEngine::Prompt.find_or_create_by(slug: "simple-test") do |p|
  p.name = "Simple Test"
  p.content = "Say hello to {{name}}"
  p.system_message = "You are helpful."
  p.model = "gpt-3.5-turbo"
  p.temperature = 0.7
  p.max_tokens = 50
  p.status = "enabled"
  p.tools = []
end

# 2. Render the prompt
rendered = prompt.render(name: "World")

# 3. Test with OpenAI (if gem and API key are available)
if ENV["OPENAI_API_KEY"] && openai_available
  puts "Testing OpenAI..."
  client = OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])
  response = rendered.execute_with(client)
  puts "OpenAI response: #{response.dig('choices', 0, 'message', 'content')}"
elsif !openai_available
  puts "OpenAI gem not available - add 'gem \"openai\"' to your Gemfile"
else
  puts "OpenAI API key not set"
end

# 4. Test with Anthropic (if gem and API key are available)
if ENV["ANTHROPIC_API_KEY"] && anthropic_available
  puts "Testing Anthropic..."
  client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
  response = rendered.execute_with(client)
  puts "Anthropic response: #{response.content}"
elsif !anthropic_available
  puts "Anthropic gem not available - add 'gem \"anthropic\"' to your Gemfile"
else
  puts "Anthropic API key not set"
end

puts "Test complete!"
