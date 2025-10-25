class OauthController < ApplicationController
  skip_before_action :require_authentication
  
  def show
    provider = params[:provider]
    callback_provider = provider == 'google' ? 'google_oauth2' : provider
    client = oauth_client(provider)
    redirect_to client.auth_code.authorize_url(
      redirect_uri: "#{base_url}/auth/#{callback_provider}/callback",
      scope: 'openid email profile'
    ), allow_other_host: true
  end

  def callback
    provider = params[:provider] == 'google_oauth2' ? 'google' : params[:provider]
    callback_provider = provider == 'google' ? 'google_oauth2' : provider
    client = oauth_client(provider)

    token = client.auth_code.get_token(params[:code], redirect_uri: "#{base_url}/auth/#{callback_provider}/callback")
    user_info = fetch_user_info(provider, token)

    user = find_or_create_user(user_info, provider)
    session[:user_id] = user.id
    session[:user_info] = user_info # Store the full response to display

    redirect_to root_path, notice: "Logged in successfully with #{provider.titleize}!"
  rescue OAuth2::Error => e
    redirect_to sign_in_path, alert: "OAuth failed: #{e.description}"
  end

  def logout
    session[:user_id] = nil
    session[:user_info] = nil
    redirect_to sign_in_path, notice: "Logged out successfully!"
  end

  private

  def base_url
    if Rails.env.development?
      "http://localhost:3000"
    else
      "https://fantasy-kings.com"
    end
  end

  def oauth_client(provider)
    case provider
    when 'google'
      OAuth2::Client.new(
        Rails.application.credentials.dig(:google_oauth, :client_id),
        Rails.application.credentials.dig(:google_oauth, :client_secret),
        site: 'https://accounts.google.com',
        authorize_url: '/o/oauth2/auth',
        token_url: '/o/oauth2/token'
      )
    else
      raise "Unknown provider: #{provider}"
    end
  end

  def fetch_user_info(provider, token)
    case provider
    when 'google'
      response = token.get('https://www.googleapis.com/oauth2/v2/userinfo')
      JSON.parse(response.body)
    else
      raise "Unknown provider: #{provider}"
    end
  end

  def find_or_create_user(user_info, provider)
    User.find_or_create_by(provider: provider, uid: user_info["id"]) do |user|
      user.email = user_info["email"]
      user.name = user_info["name"]
    end
  end
end
