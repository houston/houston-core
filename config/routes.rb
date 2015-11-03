Rails.application.routes.draw do

  resources :oauth_consumers do
    member do
      get :callback
      get :callback2
      match 'client/*endpoint' => 'oauth_consumers#client', via: [:get, :post, :put, :delete]
    end
  end

  devise_for :users, :controllers => { :sessions => "sessions" }

  root to: "welcome#index", via: :get
  get "activity" => "welcome#activity"



  # Dashboard

  get "omnibar" => "omnibar#show"



  # Testing Report

  get "testing_report" => "testing_report#index", :as => :testing_report
  get "testing_report/:slug" => "testing_report#show", :as => :project_testing_report

  scope "tickets/:ticket_id" do
    resources :testing_notes
  end



  # Test Runs

  get "projects/:slug/test_runs/:commit", to: "test_runs#show", :as => :test_run
  get "projects/:slug/test_runs/:commit/retry", to: "test_runs#confirm_retry", :as => :retry_test_run
  post "projects/:slug/test_runs/:commit/retry", to: "test_runs#retry"
  get "projects/:slug/tests/:id", to: "project_tests#index", as: :project_test



  # Pretickets

  get "pretickets/by_project/:slug", to: "project_pretickets#show", :as => :project_pretickets



  # Exceptions

  post "projects/:slug/exceptions/merge_several", to: "project_exceptions#merge_several"
  post "projects/:slug/exceptions/unmerge_several", to: "project_exceptions#unmerge_several"
  post "projects/:slug/exceptions/delete_several", to: "project_exceptions#delete_several"



  # Projects

  resources :projects do
    member do
      put :retire
    end

    post "follow", to: "project_roles#create", :as => :follow
    delete "unfollow", to: "project_roles#destroy", :as => :unfollow

    get "deploys/:id", to: "deploys#show", :as => :deploy

    post "deploy", to: "deploys#create"
    post "deploy/:environment", to: "deploys#create"
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

  get "commits/:sha", to: "commits#show"

  namespace "api" do
    namespace "v1" do
      scope "projects/:slug" do
        scope "tickets/by_number/:number" do
          get "tasks", to: "ticket_tasks#index"
          post "tasks", to: "ticket_tasks#create"
          put "tasks/:id", to: "ticket_tasks#update"
          delete "tasks/:id", to: "ticket_tasks#destroy"
        end
      end

      get "sprint/tasks", to: "sprint_tasks#index"
      get "sprint/tasks/mine", to: "sprint_tasks#mine"
      post "sprint/tasks/:project_slug/:shorthand", :to => "sprint_tasks#create"
      delete "sprint/tasks/:project_slug/:shorthand", :to => "sprint_tasks#destroy"
    end
  end



  # Sprints (pull out into a module)

  get "sprints/current", :to => "sprints#current", :as => :current_sprint
  get "sprints/:id", :to => "sprints#show", constraints: {id: /\d+/}, :as => :sprint
  get "sprints/:id/dashboard", :to => "sprints#dashboard", constraints: {id: /\d+/}
  get "sprints/dashboard", :to => "sprints#dashboard", :as => :sprint_dashboard
  put "sprints/:id/lock", :to => "sprints#lock", constraints: {id: /\d+/}

  constraints id: /\d+/, task_id: /\d+/ do
    post "sprints/:id/tasks/:task_id", :to => "sprints#add_task"
    delete "sprints/:id/tasks/:task_id", :to => "sprints#remove_task"
    post "sprints/:id/tasks/:task_id/lock", :to => "sprint_task_locks#create"
    delete "sprints/:id/tasks/:task_id/lock", :to => "sprint_task_locks#destroy"
  end



  # Authorizations

  put "credentials", to: "user_credentials#upsert"
  delete "credentials/:id", to: "user_credentials#destroy"



  # Jobs

  get "jobs", to: "jobs#show"
  post "jobs/:slug", to: "jobs#run", :as => :run_job



  # Options

  put "projects/:slug/options", to: "project_options#update"
  delete "projects/:slug/options/:key", to: "project_options#destroy"

  put "options", to: "user_options#update"
  delete "options/:key", to: "user_options#destroy"



  # Other

  # Experiments
  get "reports", to: "reports#index"
  %w{queue-age cycle-time time-to-first-test time-to-release}.each do |report|
    get "reports/#{report}", to: "reports##{report.underscore}"
  end
  get "reports/velocity", to: "reports#velocity"
  get "reports/tasks.xlsx", to: "reports#tasks_excel"

  get "sprint/reports", to: "reports#sprint"

  # Tester Bar
  match "tester_bar/:action", :controller => "tester_bar", via: [:get, :post] if Rails.env.development?



  # Support non-digested assets
  %w{vendor.css application.css vendor.js application.js}.each do |asset|
    get asset, to: (Proc.new do |env|
      begin
        if Rails.env.development?
          asset_path = "/dev-assets/#{asset}"
        else
          manifest_path = Dir.glob(File.join(Houston.root, "public/assets/manifest-*.json")).first
          manifest_data = JSON.load(File.new(manifest_path))
          asset_path = "/assets/#{manifest_data["assets"].fetch(asset)}"
        end

        [307, {"Location" => asset_path}, []]
      rescue KeyError
        [404, {}, []]
      end
    end)
  end



  # Modules

  Houston.config.modules.each do |mod|
    mount mod.engine => "/"
  end

end
