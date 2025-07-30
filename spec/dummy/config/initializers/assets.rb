# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Support both Sprockets and Propshaft
if defined?(Sprockets)
  Rails.application.config.assets.precompile += %w[prompt_engine/application.css]
  Rails.application.config.assets.paths << PromptEngine::Engine.root.join("app/assets/stylesheets")
  
  # Ensure proper concatenation in production
  Rails.application.config.assets.debug = false if Rails.env.production?
end

if defined?(Propshaft)
  Rails.application.config.assets.paths << PromptEngine::Engine.root.join("app/assets/stylesheets")
end
