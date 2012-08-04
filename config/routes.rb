Changelog::Application.routes.draw do
  
  devise_for :users
  
  root :to => "kanban#index", :via => :get
  
  match "kanban/:slug" => "project_kanban#index", :via => :get, :as => :project_kanban
  
  constraints :queue => Regexp.new(KanbanQueue.slugs.join("|")) do
    match "kanban/:slug/:queue" => "project_kanban#queue", :via => :get, :as => :project_kanban_queue
  end
  
  match "testing_report" => "testing_report#index", :via => :get, :as => :testing_report
  match "testing_report/:slug" => "testing_report#show", :via => :get, :as => :project_testing_report
  
  match "intelligence" => "intelligence#index", :via => :get, :as => :intelligence
  match "intelligence/:slug" => "intelligence#show", :via => :get, :as => :project_intelligence
  
  resources :projects do
    resources :environments, :controller => "project_environments" do
      member do
        post 'post_receive'
      end
      resources :releases
    end
  end
  
  constraints :id => /\d+/ do
    resources :users do
      member do
        post :invite
      end
    end
  end
  
  scope "tickets/:ticket_id" do 
    resources :testing_notes
  end
  
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
