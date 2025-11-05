require "rails_helper"

RSpec.describe "PromptEngine API Variable Handling", type: :model do
  # These tests verify three potential bugs in the API:
  # 1. Variables with default values should not be required
  # 2. Optional variables should not cause errors when omitted
  # 3. Both implicit and explicit hash syntax should work

  describe "Bug 1: Variables with default values" do
    let!(:prompt) do
      PromptEngine::Prompt.create!(
        name: "greeting-with-defaults",
        slug: "greeting-with-defaults",
        content: "Hello {{name}}, welcome to {{company}}!",
        status: "enabled",
        tools: []
      )
    end

    before do
      prompt.sync_parameters!
      # Set name as required with a default value
      prompt.parameters.find_by(name: "name").update!(
        required: true,
        default_value: "Guest"
      )
      # Set company as required with a default value
      prompt.parameters.find_by(name: "company").update!(
        required: true,
        default_value: "Our Platform"
      )
    end

    context "PromptEngine.render" do
      it "should not require a variable that has a default value" do
        # Should work without passing 'name' since it has a default
        result = PromptEngine.render("greeting-with-defaults", { company: "Acme Corp" })

        expect(result.content).to eq("Hello Guest, welcome to Acme Corp!")
      end

      it "should use default value for required variable when not provided" do
        # Should work with no variables since both have defaults
        result = PromptEngine.render("greeting-with-defaults", {})

        expect(result.content).to eq("Hello Guest, welcome to Our Platform!")
      end

      it "should allow overriding default values when provided" do
        result = PromptEngine.render("greeting-with-defaults", {
          name: "Alice",
          company: "TechCo"
        })

        expect(result.content).to eq("Hello Alice, welcome to TechCo!")
      end

      it "should handle partial override of defaults" do
        result = PromptEngine.render("greeting-with-defaults", { name: "Bob" })

        expect(result.content).to eq("Hello Bob, welcome to Our Platform!")
      end
    end

    context "PromptEngine.execute" do
      before do
        # Setup mock settings with API key
        allow_any_instance_of(PromptEngine::Setting).to receive(:anthropic_api_key).and_return("sk-test-key")

        # Mock PlaygroundExecutor to avoid real API calls
        allow_any_instance_of(PromptEngine::PlaygroundExecutor).to receive(:execute).and_return({
          response: "Mocked response",
          execution_time: 0.5,
          token_count: 100,
          model: "claude-3-5-sonnet-20241022",
          provider: "anthropic"
        })
      end

      it "should not require a variable with a default value" do
        expect {
          PromptEngine.execute("greeting-with-defaults", { company: "Acme Corp" })
        }.not_to raise_error
      end

      it "should work with no variables when all have defaults" do
        expect {
          PromptEngine.execute("greeting-with-defaults", {})
        }.not_to raise_error
      end

      it "should allow overriding defaults in execute" do
        expect {
          PromptEngine.execute("greeting-with-defaults", {
            name: "Charlie",
            company: "StartupCo"
          })
        }.not_to raise_error
      end
    end
  end

  describe "Bug 2: Optional variables" do
    let!(:prompt) do
      PromptEngine::Prompt.create!(
        name: "message-with-optional",
        slug: "message-with-optional",
        content: "Hello {{name}}! {{greeting}} You have {{item_count}} items.",
        status: "enabled",
        tools: []
      )
    end

    before do
      prompt.sync_parameters!
      # Set name as required
      prompt.parameters.find_by(name: "name").update!(required: true)
      # Set greeting as optional (no default)
      prompt.parameters.find_by(name: "greeting").update!(required: false)
      # Set item_count as required
      prompt.parameters.find_by(name: "item_count").update!(
        required: true,
        parameter_type: "integer"
      )
    end

    context "PromptEngine.render" do
      it "should not require optional variables" do
        result = PromptEngine.render("message-with-optional", {
          name: "Alice",
          item_count: 5
        })

        # Optional variable should render as empty or blank
        expect(result.content).to match(/Hello Alice!.*You have 5 items/)
      end

      it "should work with optional variables provided" do
        result = PromptEngine.render("message-with-optional", {
          name: "Bob",
          greeting: "Welcome back!",
          item_count: 3
        })

        expect(result.content).to eq("Hello Bob! Welcome back! You have 3 items.")
      end

      it "should not raise error when optional variable is omitted" do
        expect {
          PromptEngine.render("message-with-optional", {
            name: "Charlie",
            item_count: 0
          })
        }.not_to raise_error
      end
    end

    context "PromptEngine.execute" do
      before do
        allow_any_instance_of(PromptEngine::Setting).to receive(:anthropic_api_key).and_return("sk-test-key")
        allow_any_instance_of(PromptEngine::PlaygroundExecutor).to receive(:execute).and_return({
          response: "Mocked response",
          execution_time: 0.5,
          token_count: 100,
          model: "claude-3-5-sonnet-20241022",
          provider: "anthropic"
        })
      end

      it "should not require optional variables in execute" do
        expect {
          PromptEngine.execute("message-with-optional", {
            name: "Dave",
            item_count: 7
          })
        }.not_to raise_error
      end

      it "should work with optional variables provided in execute" do
        expect {
          PromptEngine.execute("message-with-optional", {
            name: "Eve",
            greeting: "Good morning!",
            item_count: 2
          })
        }.not_to raise_error
      end
    end
  end

  describe "Bug 3: Hash syntax parsing" do
    let!(:prompt) do
      PromptEngine::Prompt.create!(
        name: "startup-profile",
        slug: "startup-profile",
        content: "Suggestions: {{suggestions}}, Conflict: {{conflict}}, PDF: {{pdf}}",
        status: "enabled",
        tools: []
      )
    end

    before do
      prompt.sync_parameters!
    end

    context "PromptEngine.render with explicit hash braces" do
      it "should work with explicit hash braces" do
        result = PromptEngine.render("startup-profile", {
          suggestions: "value1",
          conflict: "value2",
          pdf: "value3"
        })

        expect(result.content).to eq("Suggestions: value1, Conflict: value2, PDF: value3")
      end

      it "should handle explicit hash with all required variables" do
        expect {
          PromptEngine.render("startup-profile", {
            suggestions: "test1",
            conflict: "test2",
            pdf: "test3"
          })
        }.not_to raise_error
      end
    end

    context "PromptEngine.render with implicit hash syntax" do
      it "should work with implicit hash (no braces)" do
        # Ruby allows passing key: value pairs without braces as last argument
        result = PromptEngine.render("startup-profile",
          suggestions: "value1",
          conflict: "value2",
          pdf: "value3"
        )

        expect(result.content).to eq("Suggestions: value1, Conflict: value2, PDF: value3")
      end

      it "should not confuse implicit hash variables with options" do
        # This should pass variables, not options
        expect {
          PromptEngine.render("startup-profile",
            suggestions: "val1",
            conflict: "val2",
            pdf: "val3"
          )
        }.not_to raise_error
      end

      it "should handle both variables and options correctly" do
        result = PromptEngine.render("startup-profile",
          { suggestions: "val1", conflict: "val2", pdf: "val3" },
          options: { model: "gpt-4" }
        )

        expect(result.content).to eq("Suggestions: val1, Conflict: val2, PDF: val3")
        expect(result.model).to eq("gpt-4")
      end
    end

    context "PromptEngine.execute with different hash syntaxes" do
      before do
        allow_any_instance_of(PromptEngine::Setting).to receive(:anthropic_api_key).and_return("sk-test-key")
        allow_any_instance_of(PromptEngine::PlaygroundExecutor).to receive(:execute).and_return({
          response: "Mocked response",
          execution_time: 0.5,
          token_count: 100,
          model: "claude-3-5-sonnet-20241022",
          provider: "anthropic"
        })
      end

      it "should work with explicit hash in execute" do
        expect {
          PromptEngine.execute("startup-profile", {
            suggestions: "exec1",
            conflict: "exec2",
            pdf: "exec3"
          })
        }.not_to raise_error
      end

      it "should work with implicit hash in execute" do
        expect {
          PromptEngine.execute("startup-profile",
            suggestions: "exec1",
            conflict: "exec2",
            pdf: "exec3"
          )
        }.not_to raise_error
      end
    end
  end

  describe "Combined scenarios: defaults + optional + hash syntax" do
    let!(:prompt) do
      PromptEngine::Prompt.create!(
        name: "complex-prompt",
        slug: "complex-prompt",
        content: "User: {{user_name}}, Type: {{user_type}}, Message: {{message}}, Notes: {{notes}}",
        status: "enabled",
        tools: []
      )
    end

    before do
      prompt.sync_parameters!
      # user_name: required with default
      prompt.parameters.find_by(name: "user_name").update!(
        required: true,
        default_value: "Anonymous"
      )
      # user_type: required with default
      prompt.parameters.find_by(name: "user_type").update!(
        required: true,
        default_value: "guest"
      )
      # message: required without default
      prompt.parameters.find_by(name: "message").update!(required: true)
      # notes: optional without default
      prompt.parameters.find_by(name: "notes").update!(required: false)
    end

    it "should work with only required non-default variable (explicit hash)" do
      result = PromptEngine.render("complex-prompt", { message: "Hello" })

      expect(result.content).to match(/User: Anonymous.*Type: guest.*Message: Hello/)
    end

    it "should work with only required non-default variable (implicit hash)" do
      result = PromptEngine.render("complex-prompt", message: "Hello")

      expect(result.content).to match(/User: Anonymous.*Type: guest.*Message: Hello/)
    end

    it "should handle partial overrides with optional omitted (explicit hash)" do
      result = PromptEngine.render("complex-prompt", {
        user_name: "Alice",
        message: "Hi there"
      })

      expect(result.content).to match(/User: Alice.*Type: guest.*Message: Hi there/)
    end

    it "should handle partial overrides with optional omitted (implicit hash)" do
      result = PromptEngine.render("complex-prompt",
        user_name: "Alice",
        message: "Hi there"
      )

      expect(result.content).to match(/User: Alice.*Type: guest.*Message: Hi there/)
    end

    it "should handle all variables provided (explicit hash)" do
      result = PromptEngine.render("complex-prompt", {
        user_name: "Bob",
        user_type: "admin",
        message: "Testing",
        notes: "Important"
      })

      expect(result.content).to eq("User: Bob, Type: admin, Message: Testing, Notes: Important")
    end

    it "should handle all variables provided (implicit hash)" do
      result = PromptEngine.render("complex-prompt",
        user_name: "Bob",
        user_type: "admin",
        message: "Testing",
        notes: "Important"
      )

      expect(result.content).to eq("User: Bob, Type: admin, Message: Testing, Notes: Important")
    end

    it "should handle only required variable with options override" do
      result = PromptEngine.render("complex-prompt",
        { message: "Hello" },
        options: { temperature: 0.5 }
      )

      expect(result.content).to match(/Message: Hello/)
      expect(result.temperature).to eq(0.5)
    end

    it "should fail when required non-default variable is missing" do
      expect {
        PromptEngine.render("complex-prompt", { user_name: "Alice" })
      }.to raise_error(PromptEngine::RenderError, /message is required/)
    end
  end

  describe "Edge cases" do
    let!(:prompt) do
      PromptEngine::Prompt.create!(
        name: "edge-case-prompt",
        slug: "edge-case-prompt",
        content: "Value: {{value}}",
        status: "enabled",
        tools: []
      )
    end

    before do
      prompt.sync_parameters!
    end

    context "empty string vs nil for optional parameters" do
      before do
        prompt.parameters.find_by(name: "value").update!(required: false)
      end

      it "should handle nil for optional parameter" do
        result = PromptEngine.render("edge-case-prompt", { value: nil })
        expect(result.content).to match(/Value:/)
      end

      it "should handle empty string for optional parameter" do
        result = PromptEngine.render("edge-case-prompt", { value: "" })
        expect(result.content).to match(/Value:/)
      end

      it "should handle omitted optional parameter" do
        result = PromptEngine.render("edge-case-prompt", {})
        expect(result.content).to match(/Value:/)
      end
    end

    context "empty string vs nil for required parameters with defaults" do
      before do
        prompt.parameters.find_by(name: "value").update!(
          required: true,
          default_value: "default"
        )
      end

      it "should use default when value is nil" do
        result = PromptEngine.render("edge-case-prompt", { value: nil })
        expect(result.content).to eq("Value: default")
      end

      it "should use default when value is empty string" do
        result = PromptEngine.render("edge-case-prompt", { value: "" })
        expect(result.content).to eq("Value: default")
      end

      it "should use default when variable is omitted" do
        result = PromptEngine.render("edge-case-prompt", {})
        expect(result.content).to eq("Value: default")
      end

      it "should not use default when value is explicitly provided" do
        result = PromptEngine.render("edge-case-prompt", { value: "provided" })
        expect(result.content).to eq("Value: provided")
      end
    end

    context "symbol vs string keys" do
      before do
        prompt.parameters.find_by(name: "value").update!(required: true)
      end

      it "should accept symbol keys" do
        result = PromptEngine.render("edge-case-prompt", { value: "test" })
        expect(result.content).to eq("Value: test")
      end

      it "should accept string keys" do
        result = PromptEngine.render("edge-case-prompt", { "value" => "test" })
        expect(result.content).to eq("Value: test")
      end

      it "should handle mixed symbol and string keys" do
        # Add another variable
        prompt.update!(content: "Value: {{value}}, Other: {{other}}")
        prompt.sync_parameters!

        result = PromptEngine.render("edge-case-prompt", {
          value: "test1",
          "other" => "test2"
        })
        expect(result.content).to eq("Value: test1, Other: test2")
      end
    end
  end

  describe "Instance method: prompt.render(**options)" do
    # These tests verify the same three bugs but for the instance method
    # The instance method uses keyword arguments where variables and options are mixed
    # Example: prompt.render(name: "Alice", model: "gpt-4")

    describe "Bug 1: Variables with default values (instance method)" do
      let!(:prompt) do
        PromptEngine::Prompt.create!(
          name: "greeting-with-defaults-instance",
          slug: "greeting-with-defaults-instance",
          content: "Hello {{name}}, welcome to {{company}}!",
          status: "enabled",
          tools: []
        )
      end

      before do
        prompt.sync_parameters!
        # Set name as required with a default value
        prompt.parameters.find_by(name: "name").update!(
          required: true,
          default_value: "Guest"
        )
        # Set company as required with a default value
        prompt.parameters.find_by(name: "company").update!(
          required: true,
          default_value: "Our Platform"
        )
      end

      it "should not require a variable that has a default value" do
        # Should work without passing 'name' since it has a default
        result = prompt.render(company: "Acme Corp")

        expect(result.content).to eq("Hello Guest, welcome to Acme Corp!")
      end

      it "should use default value for required variable when not provided" do
        # Should work with no variables since both have defaults
        result = prompt.render

        expect(result.content).to eq("Hello Guest, welcome to Our Platform!")
      end

      it "should allow overriding default values when provided" do
        result = prompt.render(
          name: "Alice",
          company: "TechCo"
        )

        expect(result.content).to eq("Hello Alice, welcome to TechCo!")
      end

      it "should handle partial override of defaults" do
        result = prompt.render(name: "Bob")

        expect(result.content).to eq("Hello Bob, welcome to Our Platform!")
      end

      it "should handle overrides mixed with variables" do
        result = prompt.render(
          name: "Charlie",
          model: "gpt-4",
          temperature: 0.5
        )

        expect(result.content).to eq("Hello Charlie, welcome to Our Platform!")
        expect(result.model).to eq("gpt-4")
        expect(result.temperature).to eq(0.5)
      end
    end

    describe "Bug 2: Optional variables (instance method)" do
      let!(:prompt) do
        PromptEngine::Prompt.create!(
          name: "message-with-optional-instance",
          slug: "message-with-optional-instance",
          content: "Hello {{name}}! {{greeting}} You have {{item_count}} items.",
          status: "enabled",
          tools: []
        )
      end

      before do
        prompt.sync_parameters!
        # Set name as required
        prompt.parameters.find_by(name: "name").update!(required: true)
        # Set greeting as optional (no default)
        prompt.parameters.find_by(name: "greeting").update!(required: false)
        # Set item_count as required
        prompt.parameters.find_by(name: "item_count").update!(
          required: true,
          parameter_type: "integer"
        )
      end

      it "should not require optional variables" do
        result = prompt.render(
          name: "Alice",
          item_count: 5
        )

        # Optional variable should render as empty or blank
        expect(result.content).to match(/Hello Alice!.*You have 5 items/)
      end

      it "should work with optional variables provided" do
        result = prompt.render(
          name: "Bob",
          greeting: "Welcome back!",
          item_count: 3
        )

        expect(result.content).to eq("Hello Bob! Welcome back! You have 3 items.")
      end

      it "should not raise error when optional variable is omitted" do
        expect {
          prompt.render(
            name: "Charlie",
            item_count: 0
          )
        }.not_to raise_error
      end

      it "should handle optional variables with overrides" do
        result = prompt.render(
          name: "Dave",
          item_count: 7,
          temperature: 0.3
        )

        expect(result.content).to match(/Hello Dave!.*You have 7 items/)
        expect(result.temperature).to eq(0.3)
      end
    end

    describe "Bug 3: Hash syntax (instance method - natural keyword args)" do
      let!(:prompt) do
        PromptEngine::Prompt.create!(
          name: "startup-profile-instance",
          slug: "startup-profile-instance",
          content: "Suggestions: {{suggestions}}, Conflict: {{conflict}}, PDF: {{pdf}}",
          status: "enabled",
          tools: []
        )
      end

      before do
        prompt.sync_parameters!
      end

      it "should work with keyword arguments naturally" do
        result = prompt.render(
          suggestions: "value1",
          conflict: "value2",
          pdf: "value3"
        )

        expect(result.content).to eq("Suggestions: value1, Conflict: value2, PDF: value3")
      end

      it "should handle all required variables as keyword arguments" do
        expect {
          prompt.render(
            suggestions: "test1",
            conflict: "test2",
            pdf: "test3"
          )
        }.not_to raise_error
      end

      it "should mix variables and overrides seamlessly" do
        result = prompt.render(
          suggestions: "val1",
          conflict: "val2",
          pdf: "val3",
          model: "gpt-4",
          temperature: 0.7
        )

        expect(result.content).to eq("Suggestions: val1, Conflict: val2, PDF: val3")
        expect(result.model).to eq("gpt-4")
        expect(result.temperature).to eq(0.7)
      end

      it "should correctly separate variables from override keys" do
        # 'model' should be treated as override, not a variable
        result = prompt.render(
          suggestions: "s1",
          conflict: "c1",
          pdf: "p1",
          model: "claude-3-5-sonnet-20241022"
        )

        expect(result.content).to eq("Suggestions: s1, Conflict: c1, PDF: p1")
        expect(result.model).to eq("claude-3-5-sonnet-20241022")
      end
    end

    describe "Combined scenarios: defaults + optional + keyword args (instance method)" do
      let!(:prompt) do
        PromptEngine::Prompt.create!(
          name: "complex-prompt-instance",
          slug: "complex-prompt-instance",
          content: "User: {{user_name}}, Type: {{user_type}}, Message: {{message}}, Notes: {{notes}}",
          status: "enabled",
          tools: []
        )
      end

      before do
        prompt.sync_parameters!
        # user_name: required with default
        prompt.parameters.find_by(name: "user_name").update!(
          required: true,
          default_value: "Anonymous"
        )
        # user_type: required with default
        prompt.parameters.find_by(name: "user_type").update!(
          required: true,
          default_value: "guest"
        )
        # message: required without default
        prompt.parameters.find_by(name: "message").update!(required: true)
        # notes: optional without default
        prompt.parameters.find_by(name: "notes").update!(required: false)
      end

      it "should work with only required non-default variable" do
        result = prompt.render(message: "Hello")

        expect(result.content).to match(/User: Anonymous.*Type: guest.*Message: Hello/)
      end

      it "should handle partial overrides with optional omitted" do
        result = prompt.render(
          user_name: "Alice",
          message: "Hi there"
        )

        expect(result.content).to match(/User: Alice.*Type: guest.*Message: Hi there/)
      end

      it "should handle all variables provided" do
        result = prompt.render(
          user_name: "Bob",
          user_type: "admin",
          message: "Testing",
          notes: "Important"
        )

        expect(result.content).to eq("User: Bob, Type: admin, Message: Testing, Notes: Important")
      end

      it "should handle only required variable with model override" do
        result = prompt.render(
          message: "Hello",
          model: "gpt-4"
        )

        expect(result.content).to match(/Message: Hello/)
        expect(result.model).to eq("gpt-4")
      end

      it "should handle complex mix of all types" do
        result = prompt.render(
          user_name: "Charlie",
          message: "Test message",
          notes: "Some notes",
          temperature: 0.8,
          max_tokens: 1000
        )

        expect(result.content).to match(/User: Charlie.*Type: guest.*Message: Test message.*Notes: Some notes/)
        expect(result.temperature).to eq(0.8)
        expect(result.max_tokens).to eq(1000)
      end

      it "should fail when required non-default variable is missing" do
        expect {
          prompt.render(user_name: "Alice")
        }.to raise_error(PromptEngine::RenderError, /message is required/)
      end

      it "should not confuse variable named 'model' with override key" do
        # If there was a variable named 'model' in the prompt, it should be treated as an override
        # Let's verify current behavior: 'model' is always an override key
        result = prompt.render(
          message: "Hello",
          model: "custom-model"
        )

        # 'model' should be treated as override, not variable
        expect(result.model).to eq("custom-model")
        expect(result.content).to match(/Message: Hello/)
      end
    end

    describe "Edge cases (instance method)" do
      let!(:prompt) do
        PromptEngine::Prompt.create!(
          name: "edge-case-prompt-instance",
          slug: "edge-case-prompt-instance",
          content: "Value: {{value}}",
          status: "enabled",
          tools: []
        )
      end

      before do
        prompt.sync_parameters!
      end

      context "empty string vs nil for optional parameters" do
        before do
          prompt.parameters.find_by(name: "value").update!(required: false)
        end

        it "should handle nil for optional parameter" do
          result = prompt.render(value: nil)
          expect(result.content).to match(/Value:/)
        end

        it "should handle empty string for optional parameter" do
          result = prompt.render(value: "")
          expect(result.content).to match(/Value:/)
        end

        it "should handle omitted optional parameter" do
          result = prompt.render
          expect(result.content).to match(/Value:/)
        end
      end

      context "empty string vs nil for required parameters with defaults" do
        before do
          prompt.parameters.find_by(name: "value").update!(
            required: true,
            default_value: "default"
          )
        end

        it "should use default when value is nil" do
          result = prompt.render(value: nil)
          expect(result.content).to eq("Value: default")
        end

        it "should use default when value is empty string" do
          result = prompt.render(value: "")
          expect(result.content).to eq("Value: default")
        end

        it "should use default when variable is omitted" do
          result = prompt.render
          expect(result.content).to eq("Value: default")
        end

        it "should not use default when value is explicitly provided" do
          result = prompt.render(value: "provided")
          expect(result.content).to eq("Value: provided")
        end
      end

      context "override keys behavior" do
        before do
          prompt.parameters.find_by(name: "value").update!(required: true)
        end

        it "should correctly extract model as override" do
          result = prompt.render(value: "test", model: "gpt-4")
          expect(result.content).to eq("Value: test")
          expect(result.model).to eq("gpt-4")
        end

        it "should correctly extract temperature as override" do
          result = prompt.render(value: "test", temperature: 0.9)
          expect(result.content).to eq("Value: test")
          expect(result.temperature).to eq(0.9)
        end

        it "should correctly extract max_tokens as override" do
          result = prompt.render(value: "test", max_tokens: 500)
          expect(result.content).to eq("Value: test")
          expect(result.max_tokens).to eq(500)
        end

        it "should handle multiple overrides simultaneously" do
          result = prompt.render(
            value: "test",
            model: "claude-3-5-sonnet-20241022",
            temperature: 0.7,
            max_tokens: 2000
          )
          expect(result.content).to eq("Value: test")
          expect(result.model).to eq("claude-3-5-sonnet-20241022")
          expect(result.temperature).to eq(0.7)
          expect(result.max_tokens).to eq(2000)
        end
      end
    end
  end
end
