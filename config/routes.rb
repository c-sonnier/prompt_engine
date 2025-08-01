PromptEngine::Engine.routes.draw do
  root to: "dashboard#index"

  get "dashboard", to: "dashboard#index", as: :dashboard

  resources :prompts do
    member do
      post :test
      post :duplicate
      get :playground, to: "playground#show"
      post :playground, to: "playground#execute"
    end
    collection do
      get :search
    end

    resources :versions, only: [ :index, :show ] do
      member do
        post :restore
        get :compare
      end
      resources :playground_run_results, only: [ :index ]
    end

    resources :playground_run_results, only: [ :index ]

    resources :eval_sets do
      member do
        post :run
        get :compare
        get :metrics
      end
      resources :test_cases, except: [ :index, :show ] do
        collection do
          get :import
          post :import_preview
          post :import_create
        end
      end
    end
    resources :eval_runs, only: [ :show ]
  end

  resources :playground_run_results, only: [ :index, :show ]

  resource :settings, only: [ :edit, :update ]

  # Evaluations index - shows all eval sets across all prompts
  get "evaluations", to: "evaluations#index", as: :evaluations

  # API endpoints for integration
  namespace :api do
    namespace :v1 do
      resources :prompts, only: [ :index, :show ] do
        member do
          post :execute
        end
      end
    end
  end
end
