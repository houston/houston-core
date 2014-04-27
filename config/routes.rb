Houston::Application.routes.draw do
  
  resources :oauth_consumers do
    member do
      get :callback
      get :callback2
      match 'client/*endpoint' => 'oauth_consumers#client', via: [:get, :post, :put, :delete]
    end
  end
  
  devise_for :users, :controllers => { :sessions => "sessions" }
  
  root to: "welcome#index", via: :get
  get "tdl" => "welcome#tdl"
  get "activity" => "welcome#activity"
  
  
  
  # Dashboard
  
  get "dashboard" => "dashboard#index", :as => :dashboard
  get "omnibar" => "omnibar#show"
  
  
  
  # Testing Report
  
  get "testing_report" => "testing_report#index", :as => :testing_report
  get "testing_report/:slug" => "testing_report#show", :as => :project_testing_report
  
  scope "tickets/:ticket_id" do
    resources :testing_notes
  end
  
  
  
  # Weekly Report
  
  get "weekly_report/:year/:month/:day", to: "weekly_report#show", :as => :weekly_report
  get "weekly_report", to: "weekly_report#show"
  post "weekly_report/email", to: "weekly_report#send_email"
  get "weekly_report/:year/:month/:day/email", to: "weekly_report#prepare_email", :as => :send_weekly_report
  post "weekly_report/:year/:month/:day/email", to: "weekly_report#send_email"
  
  
  
  # Test Runs
  
  get "projects/:slug/test_runs/:commit", to: "test_runs#show", :as => :test_run
  get "projects/:slug/test_runs/:commit/retry", to: "test_runs#confirm_retry", :as => :retry_test_run
  post "projects/:slug/test_runs/:commit/retry", to: "test_runs#retry"
  
  
  
  # Pretickets
  
  get "pretickets/by_project/:slug", to: "project_pretickets#show", :as => :project_pretickets
  
  
  
  # Exceptions
  
  post "projects/:slug/exceptions/merge_several", to: "project_exceptions#merge_several"
  post "projects/:slug/exceptions/unmerge_several", to: "project_exceptions#unmerge_several"
  post "projects/:slug/exceptions/delete_several", to: "project_exceptions#delete_several"
  
  
  
  # Projects
  
  get "projects/dependencies", to: "project_dependencies#index"
  
  resources :projects do
    member do
      put :retire
    end
    
    post "follow", to: "project_roles#create", :as => :follow
    delete "unfollow", to: "project_roles#destroy", :as => :unfollow
    
    post "deploy", to: "deploys#create"
    post "deploy/:environment", to: "deploys#create"
  end
  
  
  
  # Web Hooks
  
  scope "projects/:project_id" do
    constraints :hook => /[\w\d\-_]+/ do
      get "hooks/:hook", to: "project_hooks#trigger", :as => :web_hook
      post "hooks/:hook", to: "project_hooks#trigger"
    end
  end
  
  
  
  # Releases
  
  scope "projects/:project_id" do
    get "releases", to: "releases#index"
    scope "environments/:environment" do
      resources :releases
    end
  end
  
  
  
  # Teammates
  
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
  
  get "projects/:slug/tickets", to: "project_tickets#index"
  get "projects/:slug/tickets/open", to: "project_tickets#open"
  post "projects/:slug/tickets", to: "project_tickets#create"
  
  scope "projects/:slug" do
    get "tickets/new", to: "project_tickets#new", as: :new_ticket
  end
  
  scope "projects/:slug" do
    get "tickets/sync", to: "project_tickets_sync#show", as: :project_tickets_sync
    post "tickets/sync", to: "project_tickets_sync#create"
  end
  
  
  
  
  # Settings
  
  get "settings", to: "settings#show"
  put "settings", to: "settings#update"
  
  
  
  # API
  
  get "commits", to: "commits#index"
  
  scope "self" do
    get "commits", to: "commits#self"
  end
  
  get "commits/:sha", to: "commits#show"
  
  
  
  # Modules
  
  Houston.config.modules.each do |mod|
    mount mod.engine => mod.path
  end
  
  
  
  # Authorizations
  
  put "credentials", to: "user_credentials#upsert"
  delete "credentials/:id", to: "user_credentials#destroy"
  
  
  
  # Options
  
  put "projects/:slug/options", to: "project_options#update"
  delete "projects/:slug/options/:key", to: "project_options#destroy"
  
  put "options", to: "user_options#update"
  delete "options/:key", to: "user_options#destroy"
  
  
  
  # Other
  
  # Experiments
  get "pull_requests", to: "pull_requests#index", as: :pull_requests if Houston.config.supports_pull_requests?
  
  # Tester Bar
  match "tester_bar/:action", :controller => "tester_bar", via: [:get, :post] if Rails.env.development?
  
end
