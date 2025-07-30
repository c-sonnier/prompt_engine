# desc "Explaining what the task does"
# task :prompt_engine do
#   # Task goes here
# end

namespace :prompt_engine do
  desc "Setup dummy app for development and testing"
  task setup: :environment do
    puts "Setting up PromptEngine dummy app..."

    dummy_root = File.expand_path("../../spec/dummy", __dir__)

    Dir.chdir(dummy_root) do
      # Remove existing migrations and schema
      FileUtils.rm_rf(Dir.glob("db/migrate/*"))
      FileUtils.rm_f("db/schema.rb")
      FileUtils.rm_f("db/development.sqlite3")
      FileUtils.rm_f("db/test.sqlite3")

      # Install engine migrations
      system("bundle exec rails prompt_engine:install:migrations")

      # Create and migrate databases
      system("bundle exec rails db:create")
      system("bundle exec rails db:migrate")
      system("RAILS_ENV=test bundle exec rails db:create")
      system("RAILS_ENV=test bundle exec rails db:migrate")

      puts "✅ PromptEngine dummy app setup complete!"
    end
  end

 desc "Build assets for gem packaging"
  task :build_assets do
    puts "Building PromptEngine assets..."

    # Ensure the builds directory exists
    builds_dir = File.expand_path("../../app/assets/builds", __dir__)
    FileUtils.mkdir_p(builds_dir)

    # Change to dummy app directory for asset compilation
    dummy_dir = File.expand_path("../../spec/dummy", __dir__)

    Dir.chdir(dummy_dir) do
      # Clean first
      system("bundle exec rails assets:clobber") if File.exist?("tmp")

      # Detect which asset pipeline is being used
      using_propshaft = system("bundle exec rails runner 'puts defined?(Propshaft) ? \"propshaft\" : \"sprockets\"'") rescue false

      puts "Detected asset pipeline: #{using_propshaft ? 'Propshaft' : 'Sprockets'}"

      # Precompile assets
      puts "Precompiling assets..."
      success = system("bundle exec rails assets:precompile")

      unless success
        puts "❌ Asset precompilation failed"
        exit 1
      end

      # Find compiled CSS - try multiple patterns
      compiled_patterns = [
        "public/assets/prompt_engine/application-*.css",
        "public/assets/prompt_engine/application.css",
        "public/assets/**/prompt_engine*application*.css"
      ]

      compiled_file = nil
      compiled_patterns.each do |pattern|
        files = Dir.glob(pattern)
        if files.any?
          compiled_file = files.max_by { |f| File.mtime(f) }
          break
        end
      end

      if compiled_file && File.exist?(compiled_file)
        target_file = File.join(builds_dir, "application.css")
        FileUtils.cp(compiled_file, target_file)

        file_size = File.size(target_file)
        if file_size > 100
          puts "✓ Copied compiled CSS to app/assets/builds/ (#{file_size} bytes)"

          # Show preview to verify content
          content_preview = File.read(target_file, 200)
          puts "Preview: #{content_preview[0..100]}..."
        else
          puts "⚠ Compiled CSS file seems too small (#{file_size} bytes)"
        end
      else
        puts "❌ No compiled CSS found"
        puts "Searching in public/assets:"
        Dir.glob("public/assets/**/*").select { |f| File.file?(f) }.each do |f|
          puts "  #{f} (#{File.size(f)} bytes)"
        end
        exit 1
      end

      # Clean up
      system("bundle exec rails assets:clobber") if File.exist?("tmp")
    end

    puts "✅ Asset build complete"
  end
end
