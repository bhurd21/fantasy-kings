OAuth Authentication in Rails with Google and GitHub (2025 Guide)
30 Apr, 2025
Pete Hawkins
Discussion (0)
Buy me a coffee
Tired of bulky authentication libraries cluttering your Rails apps? You're not alone. Many Rails developers crave simplicity but get complexity instead.

In this guide, you'll learn how to implement clean and minimal OAuth login with Rails 8 and the lightweight oauth2 gem. We'll provide clear, step-by-step instructions and concise Ruby code snippets for integrating Google and GitHub sign-ins.

Simplify your OAuth setup and keep your Rails apps lean. Let's dive in!

Why Use OAuth in Rails?
OAuth makes logging into apps simple and secure by allowing users to authenticate through services they already trust, like Google and GitHub. It eliminates the need to store and manage user passwords, enhancing security and improving the user experience. Additionally, OAuth reduces friction in user sign-ups, boosting your app’s adoption rates.

Whether you're building a new application or upgrading an existing one, OAuth provides a streamlined, reliable authentication method tailored perfectly for modern Rails apps.

Setting Up Your Rails App for OAuth
Before we start integrating OAuth, let's prepare your Rails application. Here's what you need:

A Rails 8 application ready to go.
The oauth2 gem installed in your Gemfile:
gem 'oauth2'
Run the following command to install the gem:

bundle install
With these simple steps, your Rails app is now set up and ready for OAuth integration.

Registering Your App with Google and GitHub
You'll need to register your Rails application with Google and GitHub to obtain OAuth credentials. Use these URLs as your callback endpoints:

Google OAuth Callback URL:  https://yourapp.com/oauth/google/callback 
GitHub OAuth Callback URL:  https://yourapp.com/oauth/github/callback 
Google OAuth Registration:
Navigate to the Google Cloud Console.
Create a new project or select an existing one.
Go to "APIs & Services" > "Credentials" and create an OAuth client ID.
Choose "Web application," configure the authorized redirect URI, and save.
GitHub OAuth Registration:
Go to your GitHub Developer Settings.
Click "New OAuth App," fill in your application details, and set your redirect URI.
Click "Register application" to generate your client ID and client secret.
Keep these credentials handy, as we'll use them to set up OAuth flows.

Building the OAuth Flow
We'll create a generic OAuth controller and routes to handle multiple providers cleanly.

Routes Setup
First, let's set up flexible routes in your config/routes.rb file to handle OAuth requests and callbacks dynamically:

resources :oauth, param: :provider, controller: "oauth", only: :show do
  get :callback, on: :member
end
This will create clean URLs for initiating and handling OAuth responses:

Initiating OAuth flow: /oauth/:provider
Handling OAuth callback: /oauth/:provider/callback
OAuth Controller
Create the OAuth controller (app/controllers/oauth_controller.rb) to handle requests and callbacks dynamically:

class OauthController < ApplicationController
  def show
    provider = params[:provider]
    client = oauth_client(provider)
    redirect_to client.auth_code.authorize_url(redirect_uri: callback_oauth_url(provider))
  end

  def callback
    provider = params[:provider]
    client = oauth_client(provider)

    token = client.auth_code.get_token(params[:code], redirect_uri: callback_oauth_url(provider))
    user_info = fetch_user_info(provider, token)

    session[:user_id] = find_or_create_user(user_info, provider).id

    redirect_to root_path, notice: "Logged in successfully with #{provider.titleize}!"
  rescue OAuth2::Error => e
    redirect_to root_path, alert: "OAuth failed: #{e.description}"
  end

  private

  # Methods `oauth_client`, `fetch_user_info`, and `find_or_create_user` will be detailed in the next sections.
end
Storing and Managing OAuth Users
To manage OAuth users efficiently, you'll store basic user details such as provider and uid. Here's a simple setup:

Create a migration for the users table:

rails generate model User provider:string uid:string name:string email:string
rails db:migrate
Implement the find_or_create_user method inside your OauthController:

def find_or_create_user(user_info, provider)
  User.find_or_create_by(provider: provider, uid: user_info["id"]) do |user|
    user.email = user_info["email"]
    user.name = user_info["name"] || user_info["login"]
  end
end
Now, your app efficiently handles user sessions by either finding an existing user or creating a new one from OAuth data.

Securing the OAuth Flow
Securing your OAuth implementation is crucial. Follow these best practices to ensure robust security:

State Parameter: Include a state parameter in OAuth requests to prevent CSRF attacks.
HTTPS: Always use HTTPS in production to protect sensitive information.
Secure Session Management: Set session cookies securely:
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store, key: '_your_app_session', secure: Rails.env.production?, httponly: true, same_site: :lax
You can also set a signed permanent cookie:

cookies.signed.permanent[:user_id] = { value: user.id, httponly: true }
Token Security: Store OAuth credentials securely using Rails credentials:
# Accessing credentials
Rails.application.credentials.dig(:oauth, :google, :client_id)
For more details, refer to the official Rails Credentials Guide.

Implementing these practices will keep your OAuth integration secure and reliable.

Conclusion
Congratulations! You've successfully set up a clean and minimal OAuth authentication solution in your Rails application using Google and GitHub. By following these best practices, you've enhanced the security and maintainability of your app, ensuring a better experience for your users and peace of mind for you as a developer.