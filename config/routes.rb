Rails.application.routes.draw do
  root "home#index"

  # Authentication
  get "sign_in", to: "auth#sign_in"
  get "logout", to: "oauth#logout"
  
  # OAuth
  resources :oauth, param: :provider, controller: "oauth", only: :show do
    get :callback, on: :member
  end
  get "/auth/:provider/callback", to: "oauth#callback"

  # Betting
  post "bets", to: "home#create_bet"
  
  # Mobile nav routes
  get "week/:week", to: "home#week", as: :week
  get "profile", to: "home#profile"
  get "settings", to: "home#settings"

  get "up" => "rails/health#show", as: :rails_health_check
end
