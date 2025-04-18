Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  root to: redirect('/')

  namespace :api do
    namespace :v1 do
      
    end
  end
  post '/users', to: 'users#create'
  delete '/@:username', to: 'users#destroy'
  post '/@:username', to: 'user_messages#create'
  post '/@:username/blocks', to: 'blocks#create'
  patch '/@:username', to: 'users#update_webhook'
end
