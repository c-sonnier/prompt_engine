require "bundler/setup"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

require "rspec/core"
require "rspec/core/rake_task"

# Load engine-specific tasks
Dir[File.join(__dir__, 'lib', 'tasks', '*.rake')].each { |f| load f }

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**{,/*/**}/*_spec.rb"
end

# Add setup task shortcut
desc "Setup PromptEngine dummy app for development and testing"
task setup: "app:prompt_engine:setup"

task default: :spec

# Add to existing Rakefile
desc "Prepare gem for publishing (build assets, run tests)"
task :prepare_release do
  puts "🔧 Preparing PromptEngine for release..."

  # Build assets
  Rake::Task["app:prompt_engine:build_assets"].invoke

  # Run tests to ensure everything works
  Rake::Task["spec"].invoke

  # Build the gem
  Rake::Task["build"].invoke

  puts "✅ Ready for publishing!"
end
