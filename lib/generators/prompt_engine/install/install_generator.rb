# frozen_string_literal: true

require "rails/generators/base"

module PromptEngine
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def install_migrations
        say_status :run, "rails prompt_engine:install:migrations", :green
        rails_command "prompt_engine:install:migrations"
      end

      def mount_engine
        return if routes_already_mounted?

        route <<~RUBY
          # Mount PromptEngine; wrap in your authentication constraints if needed.
          mount PromptEngine::Engine => "/prompt_engine"
        RUBY

        say_status :insert, "mount PromptEngine::Engine => \"/prompt_engine\"", :green
      end

      def copy_initializer
        return if initializer_exists?

        template "initializer.rb", "config/initializers/prompt_engine.rb"
        say_status :create, "config/initializers/prompt_engine.rb", :green
      end

      def display_next_steps
        say <<~MSG

          PromptEngine installed!

          Next steps:
            • Run: bin/rails db:migrate
            • Configure provider credentials or authentication inside config/initializers/prompt_engine.rb
            • Restart your Rails server and visit /prompt_engine

          Remember to rerun `bin/rails prompt_engine:install:migrations` after upgrading the gem to pick up new migrations.
        MSG
      end

      private

      def routes_already_mounted?
        return false unless File.exist?(routes_path)

        File.read(routes_path).include?("PromptEngine::Engine")
      end

      def routes_path
        @routes_path ||= File.expand_path("config/routes.rb", destination_root)
      end

      def initializer_exists?
        File.exist?(File.join(destination_root, "config/initializers/prompt_engine.rb"))
      end
    end
  end
end
