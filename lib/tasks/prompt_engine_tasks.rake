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
      # Precompile just the engine's assets
      system("bundle exec rails assets:precompile RAILS_ENV=production")

      # Copy the compiled engine assets to the builds directory
      compiled_css = "public/assets/prompt_engine/application-*.css"
      if Dir.glob(compiled_css).any?
        latest_css = Dir.glob(compiled_css).max_by { |f| File.mtime(f) }
        FileUtils.cp(latest_css, File.join(builds_dir, "application.css"))
        puts "✓ Copied compiled CSS to app/assets/builds/"
      else
        puts "⚠ No compiled CSS found at #{compiled_css}"
      end

      # Clean up
      system("bundle exec rails assets:clobber")
    end

    puts "✅ Asset build complete"
  end
end
