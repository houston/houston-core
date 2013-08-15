Houston::Application.routes.draw do
  
  devise_for :users, :controllers => { :sessions => "sessions" }
  
  root :to => "projects#index", :via => :get
  
  
  
  # Dashboard
  
  match "dashboard" => "dashboard#index", :via => :get, :as => :dashboard
  match "dasbhoard/:slug" => "project_dashboard#index", :via => :get, :as => :project_dashboard
  
  
  
  # Kanban
  
  match "kanban" => "kanban#index", :via => :get, :as => :kanban
  match "kanban/:slug" => "project_kanban#index", :via => :get, :as => :project_kanban
  
  constraints queue: Regexp.new(KanbanQueue.slugs.join("|")) do
    match "kanban/:slug/:queue" => "project_kanban#queue", :via => :get, :as => :project_kanban_queue
  end
  
  
  
  # Testing Report
  
  match "testing_report" => "testing_report#index", :via => :get, :as => :testing_report
  match "testing_report/:slug" => "testing_report#show", :via => :get, :as => :project_testing_report
  
  match "tickets/:id", :to => "tickets#show", :via => :get
  match "tickets/:id", :to => "tickets#update", :via => :put
  match "tickets/:id", :to => "tickets#close", :via => :delete
  
  post "projects/:slug/tickets", :to => "tickets#create"
  
  scope "tickets/:ticket_id" do
    resources :testing_notes
  end
  
  
  
  # Weekly Report
  
  match "weekly_report", :to => "weekly_report#show"
  match "weekly_report/:year/:month/:day", :to => "weekly_report#show", :as => :weekly_report
  match "weekly_report/email", :to => "weekly_report#send_email", :via => :post
  match "weekly_report/:year/:month/:day/email", :to => "weekly_report#prepare_email", :as => :send_weekly_report, :via => :get
  match "weekly_report/:year/:month/:day/email", :to => "weekly_report#send_email", :as => :send_weekly_report, :via => :post
  
  
  
  # Test Runs
  
  get "projects/:slug/test_runs/:commit", :to => "test_runs#show"
  
  
  
  # Projects
  
  match "projects/dependencies", :to => "project_dependencies#index", :via => :get
  
  resources :projects do
    member do
      put :retire
    end
    
    post "follow", :to => "project_roles#create", :as => :follow
    delete "unfollow", :to => "project_roles#destroy", :as => :unfollow
    
    match "deploy", :to => "deploys#create", :via => :post
    match "deploy/:environment", :to => "deploys#create", :via => :post
  end
  
  
  
  # Web Hooks
  
  scope "projects/:project_id" do
    constraints :hook => /[\w\d\-_]+/ do
      match "hooks/:hook", :to => "project_hooks#trigger", :via => :post, :as => :web_hook
    end
  end
  
  
  
  # Releases
  
  scope "projects/:project_id" do
    match "releases", :to => "releases#index"
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
  
  
  
  # Settings
  
  get "settings", to: "settings#show"
  put "settings", to: "settings#update"
  
  
  
  # API
  
  get "commits", to: "commits#index"
  
  scope "self" do
    get "commits", to: "commits#self"
  end
  
  
  
  # Modules
  
  Houston.config.modules.each do |mod|
    mount mod.engine => mod.path
  end
  
  
  
  # Authorizations
  
  put "credentials", to: "user_credentials#upsert"
  delete "credentials/:id", to: "user_credentials#destroy"
  
  
  
  # Other
  
  # Experiment
  match "tickets", :to => "tickets#index", :via => :get
  
  # Tester Bar
  match "tester_bar/:action", :controller => "tester_bar" if Rails.env.development?
  
  # This just renders a fake Kanban:
  # to give you an idea of what your queues, colors, and ages will look like
  match "demo", :to => "demo#index", :via => :get
  
end
