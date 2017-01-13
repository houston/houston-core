Rails.application.routes.draw do

  devise_for :users, :controllers => { :sessions => "sessions" }

  root to: "teams#index", via: :get



  # Test Runs

  get "test_runs/:commit", to: "test_runs#show"
  get "projects/:slug/test_runs/:commit", to: "test_runs#show", :as => :test_run
  get "projects/:slug/test_runs/:commit/retry", to: "test_runs#confirm_retry", :as => :retry_test_run
  post "projects/:slug/test_runs/:commit/retry", to: "test_runs#retry"
  put "projects/:slug/test_runs/:commit/results", to: "test_runs#save_results"

  get "projects/:slug/tests", to: "project_tests#index", as: :project_tests
  get "projects/:slug/tests/:id", to: "project_tests#show", as: :project_test



  # Teams

  resources :teams

  scope "teams/:team_id" do
    resources :projects, only: [:new]

    get "projects/new/github", to: "projects#new_from_github", as: :add_github_projects
    post "projects/new/github", to: "projects#create_from_github"
  end



  # Projects

  resources :projects, except: [:new] do
    member do
      put :retire
    end

    post "follow", to: "project_roles#create", :as => :follow
    delete "unfollow", to: "project_roles#destroy", :as => :unfollow
  end



  # Web Hooks

  post "hooks/github", to: "hooks#github"
  post "hooks/:hook", to: "hooks#trigger"

  scope "projects/:project_id" do
    constraints :hook => /[\w\d\-_]+/ do
      get "hooks/:hook", to: "project_hooks#trigger", :as => :web_hook
      post "hooks/:hook", to: "project_hooks#trigger"
    end
  end



  # Deploys

  scope "projects/:project_id" do
    get "deploys/:id", to: "deploys#show", :as => :deploy

    post "deploy", to: "deploys#create"
    post "deploy/:environment", to: "deploys#create"
  end



  # Users

  constraints :id => /\d+/ do
    resources :users do
      member do
        post :invite
      end
    end
  end



  # Tickets

  get "tickets/new", to: "tickets#new"
  get "tickets/:id", to: "tickets#show"
  put "tickets/:id", to: "tickets#update"
  delete "tickets/:id/close", to: "tickets#close"
  delete "tickets/:id/reopen", to: "tickets#reopen"

  scope "projects/:slug" do
    get "tickets", to: "project_tickets#index", as: :project_tickets
    get "tickets/open", to: "project_tickets#open", as: :project_open_tickets

    get "bugs", to: "project_tickets#bugs", as: :project_bugs
    get "bugs/open", to: "project_tickets#open_bugs", as: :project_open_bugs
    get "ideas", to: "project_tickets#ideas", as: :project_ideas
    get "ideas/open", to: "project_tickets#open_ideas", as: :project_open_ideas

    get "tickets/by_number/:number", to: "project_tickets#show", as: :project_ticket
    post "tickets/by_number/:number/close", to: "project_tickets#close", as: :close_ticket
    post "tickets/by_number/:number/reopen", to: "project_tickets#reopen", as: :reopen_ticket

    get "tickets/new", to: "project_tickets#new", as: :new_ticket
    post "tickets", to: "project_tickets#create"
  end

  scope "projects/:slug" do
    get "tickets/sync", to: "project_tickets_sync#show", as: :project_tickets_sync
    post "tickets/sync", to: "project_tickets_sync#create"
  end



  # Tasks

  put "tasks/:id", :to => "tasks#update", constraints: {id: /\d+/}
  put "tasks/:id/complete", :to => "tasks#complete", constraints: {id: /\d+/}
  put "tasks/:id/reopen", :to => "tasks#reopen", constraints: {id: /\d+/}



  # Settings

  get "settings", to: "settings#show"
  put "settings", to: "settings#update"



  # Uploads

  post "uploads/policies", to: "uploads#policies"



  # API

  get "commits", to: "commits#index"

  scope "self" do
    get "commits", to: "commits#self"
  end

  get "commits/:sha", to: "commits#show", as: :commit

  namespace "api" do
    namespace "v1" do
      get "projects", to: "projects#index"

      scope "projects/:slug" do
        scope "tickets/by_number/:number" do
          get "tasks", to: "ticket_tasks#index"
          post "tasks", to: "ticket_tasks#create"
          put "tasks/:id", to: "ticket_tasks#update"
          delete "tasks/:id", to: "ticket_tasks#destroy"
        end
      end

      get "measurements", to: "measurements#index"
    end
  end



  # Authorizations

  put "credentials", to: "user_credentials#upsert"
  delete "credentials/:id", to: "user_credentials#destroy"

  get "authorizations" => "authorizations#index", as: :authorizations
  get "authorizations/new" => "authorizations#new", as: :new_authorization
  post "authorizations" => "authorizations#create"
  get "authorizations/:id/edit" => "authorizations#edit", as: :edit_authorization
  patch "authorizations/:id" => "authorizations#update", as: :authorization

  get "authorizations/:id/grant" => "authorizations#grant", as: :grant_authorization
  get "authorizations/:id/granted" => "authorizations#granted", as: :authorization_granted
  get "oauth2/callback" => "authorizations#oauth2_callback", as: :oauth2_callback

  get "oauth/providers" => "oauth/providers#index", as: :oauth_providers
  get "oauth/providers/new" => "oauth/providers#new", as: :new_oauth_provider
  post "oauth/providers" => "oauth/providers#create"
  get "oauth/providers/:id/edit" => "oauth/providers#edit", as: :edit_oauth_provider
  patch "oauth/providers/:id" => "oauth/providers#update", as: :oauth_provider



  # Actions

  get "actions", to: "actions#index", as: :actions
  get "actions/running", to: "actions#running", as: :running_actions
  get "actions/:slug", to: "actions#show", as: :action, constraints: { slug: /[^\/]+/ }
  post "actions/:slug", to: "actions#run", as: :run_action, constraints: { slug: /[^\/]+/ }



  # Triggers

  get "triggers", to: "triggers#index", as: :triggers



  # Errors

  get "errors", to: "errors#index", as: :errors



  # Options

  put "projects/:slug/options", to: "project_options#update"
  delete "projects/:slug/options/:key", to: "project_options#destroy"

  put "options", to: "user_options#update"
  delete "options/:key", to: "user_options#destroy"



  # Other

  # Experiments
  get "pulls", to: "github/pulls#index"

  # Tester Bar
  match "tester_bar/:action", :controller => "tester_bar", via: [:get, :post] if Rails.env.development?



  # Modules

  Houston.config.modules.each do |mod|
    mount mod.engine => "/"
  end



  # The Instance

  if defined?(Houston::Engine)
    mount Houston::Engine => "/"
  end

end
