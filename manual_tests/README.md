# Manual Tests for PromptEngine

This folder contains manual test scripts to verify that the `execute_with` method works correctly with different AI clients.

## Quick Start

1. **Set up your API keys:**
   ```bash
   export OPENAI_API_KEY="your-openai-key"
   export ANTHROPIC_API_KEY="your-anthropic-key"
   ```

2. **Open Rails console:**
   ```bash
   rails console
   ```

3. **Run a test:**
   Copy and paste the contents of any test file into the Rails console.

## Test Files

### 🚀 **Quick Tests**

- **`simple_test.rb`** - Basic test for both OpenAI and Anthropic clients
- **`test_anthropic_only.rb`** - Test only Anthropic client (recommended to start here)

### 🔧 **Debugging Tests**

- **`debug_clients.rb`** - Check what gems are available and their methods
- **`test_client_api.rb`** - Understand the exact API of each client
- **`investigate_openai.rb`** - Deep dive into OpenAI client API

### 🧪 **Comprehensive Tests**

- **`test_execute_with.rb`** - Full test suite for all clients
- **`test_with_ruby_llm.rb`** - Test using ruby_llm gem instead of direct gems
- **`test_openai_simple.rb`** - Simple OpenAI-specific test

## Usage Examples

### Test Anthropic Only
```bash
rails console
# Then copy and paste the contents of test_anthropic_only.rb
```

### Test Both Clients
```bash
rails console
# Then copy and paste the contents of simple_test.rb
```

### Debug Client APIs
```bash
rails console
# Then copy and paste the contents of debug_clients.rb
```

## Prerequisites

See [SETUP_GEMS.md](SETUP_GEMS.md) for detailed setup instructions.

### Quick Setup
Add these to your `Gemfile`:
```ruby
gem 'openai'
gem 'anthropic'
```

Then run:
```bash
bundle install
```

Set your API keys:
```bash
export OPENAI_API_KEY="your-openai-api-key"
export ANTHROPIC_API_KEY="your-anthropic-api-key"
```

## Troubleshooting

### Common Issues

1. **"Gem not found"** - Install the required gems
2. **"API key not set"** - Set your environment variables
3. **"Wrong number of arguments"** - The client API is different than expected
4. **"Model not found"** - Use the correct model for each provider

### Getting Help

- Start with `debug_clients.rb` to understand your client APIs
- Use `test_anthropic_only.rb` first (usually works better)
- Check the error messages for specific guidance

## What These Tests Verify

✅ **Client Detection** - Correctly identifies OpenAI vs Anthropic clients  
✅ **Parameter Conversion** - Properly formats parameters for each client  
✅ **API Integration** - Actually calls the APIs and gets responses  
✅ **Error Handling** - Graceful handling of missing gems/keys  
✅ **Response Processing** - Correctly handles different response formats  

## Success Indicators

- ✅ **Anthropic**: Should get a response from Claude
- ✅ **OpenAI**: Should get a response from GPT (if API works)
- ✅ **Error Handling**: Should show helpful error messages for issues

## File Descriptions

| File | Purpose | When to Use |
|------|---------|-------------|
| `simple_test.rb` | Quick test of both clients | First test to run |
| `test_anthropic_only.rb` | Anthropic-only test | When OpenAI has issues |
| `debug_clients.rb` | Check available methods | When debugging API issues |
| `test_client_api.rb` | Understand client APIs | When client behavior is unclear |
| `test_execute_with.rb` | Comprehensive test suite | Full verification |
| `investigate_openai.rb` | OpenAI-specific debugging | When OpenAI doesn't work |
| `test_with_ruby_llm.rb` | Test with ruby_llm gem | Alternative to direct gems |
| `test_openai_simple.rb` | Simple OpenAI test | OpenAI-specific issues |
