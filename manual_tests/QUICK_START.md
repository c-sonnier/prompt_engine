# Quick Start Guide

## 🚀 Test the `execute_with` Method in 3 Steps

### Step 1: Set up Gems and API Keys
See [SETUP_GEMS.md](SETUP_GEMS.md) for detailed setup instructions.

Quick setup:
```bash
# Add to Gemfile: gem 'anthropic'
bundle install
export ANTHROPIC_API_KEY="your-anthropic-key"
```

### Step 2: Open Rails Console
```bash
rails console
```

### Step 3: Run a Test
Copy and paste the contents of `test_anthropic_only.rb` into the console.

## 🎯 What You Should See

### ✅ Success
```
=== Testing Anthropic Client Only ===
✓ Anthropic gem available
✓ Anthropic API key available
✓ Anthropic client created
Testing execute_with method...
✅ Anthropic test successful!
Response: {:id=>"msg_...", :content=>[...], :model=>"claude-3-haiku-20240307", ...}
```

### ❌ Common Issues

**"Gem not available"**
```bash
# Add to Gemfile
gem 'anthropic'
bundle install
```

**"API key not set"**
```bash
export ANTHROPIC_API_KEY="your-key"
```

**"Model not found"**
- The test uses the correct Claude model automatically

## 🔧 Next Steps

1. **If Anthropic works**: Try `simple_test.rb` to test both clients
2. **If you have issues**: Use `debug_clients.rb` to understand your setup
3. **For comprehensive testing**: Use `test_execute_with.rb`

## 📁 Available Tests

- **`test_anthropic_only.rb`** ← Start here (recommended)
- **`simple_test.rb`** ← Test both clients
- **`debug_clients.rb`** ← Debug issues
- **`test_execute_with.rb`** ← Full test suite

## 🆘 Need Help?

Check the [README.md](README.md) for detailed troubleshooting and explanations.
