Rails.application.routes.draw do
  # Health check
  get '/health', to: 'health#show'

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      devise_for :users, controllers: {
        sessions: 'api/v1/sessions',
        registrations: 'api/v1/registrations'
      }

      # Search endpoints
      namespace :search do
        post :global, to: 'global#search'
        get :autocomplete, to: 'autocomplete#suggest'
        get :facets, to: 'facets#index'
        post :advanced, to: 'advanced#search'
      end

      # Resource endpoints (for CRUD operations)
      resources :orders, only: [:index, :show, :create, :update]
      resources :billings, only: [:index, :show, :create, :update]
      resources :invoices, only: [:index, :show, :create, :update]
      resources :accounts, only: [:index, :show, :create, :update]
      resources :drivers, only: [:index, :show, :create, :update]
      resources :fleets, only: [:index, :show, :create, :update]
      resources :pods, only: [:index, :show, :create, :update]

      # Analytics
      namespace :analytics do
        get 'search_stats', to: 'search#stats'
        get 'popular_searches', to: 'search#popular'
      end
    end
  end

  # Root route
  root to: proc { [200, {}, ['Logistics Search API - v1.0.0']] }
end
