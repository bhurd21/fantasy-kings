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
  get "weekly_budget/:week", to: "home#weekly_budget", as: :weekly_budget
  patch "betting_histories/:id/update_result", to: "home#update_bet_result", as: :update_bet_result
  
  # Admin
  post "admin/refresh_games", to: "home#refresh_games", as: :refresh_games
  post "admin/place_liams_bet", to: "home#place_liams_bet", as: :place_liams_bet
  
  # Mobile nav routes
  get "week/:week", to: "home#week", as: :week
  get "leaderboard", to: "home#leaderboard", as: :leaderboard
  get "profile", to: "home#profile"
  get "users/:id", to: "home#user_profile", as: :user_profile
  get "settings", to: "home#settings"
  patch "update_nickname", to: "home#update_nickname", as: :update_nickname

  get "up" => "rails/health#show", as: :rails_health_check
end
