# frozen_string_literal: true

# Configure PromptEngine hooks here.
#
# Examples:
# - Lock the admin UI behind authentication
# - Override default providers or add middleware
#
# ActiveSupport.on_load(:prompt_engine_application_controller) do
#   before_action :authenticate_admin!
# end
#
# PromptEngine::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
#   # secure credential comparison here
# end
