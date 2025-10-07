# Setup Instructions for execute_with Testing

To test the `execute_with` method with both OpenAI and Anthropic clients, you need to install the required gems.

## Required Gems

Add these gems to your `Gemfile`:

```ruby
# For OpenAI integration
gem 'openai'

# For Anthropic integration  
gem 'anthropic'
```

## Installation Steps

1. **Add the gems to your Gemfile:**
   ```bash
   echo 'gem "openai"' >> Gemfile
   echo 'gem "anthropic"' >> Gemfile
   ```

2. **Install the gems:**
   ```bash
   bundle install
   ```

3. **Set up your API keys:**
   ```bash
   export OPENAI_API_KEY="your-openai-api-key"
   export ANTHROPIC_API_KEY="your-anthropic-api-key"
   ```

## Testing

Once the gems are installed and API keys are set, you can run the tests:

### Option 1: Simple Test (Rails Console)
```bash
rails console
```
Then copy and paste the contents of `simple_test.rb`

### Option 2: Comprehensive Test
```bash
ruby test_execute_with.rb
```

## Alternative: Using ruby_llm

Since your project already includes `ruby_llm`, you might be able to use that instead of the direct gems. The `execute_with` method is designed to work with any client that has a `chat` method, so if `ruby_llm` provides OpenAI and Anthropic clients, you could use those instead.

Check the `ruby_llm` documentation to see if it provides:
- `RubyLLM::OpenAI::Client`
- `RubyLLM::Anthropic::Client`

If so, you could modify the test to use those clients instead of requiring the separate gems.
