class AuthController < ApplicationController
  skip_before_action :require_authentication
  
  def sign_in
    # Show the sign-in page
  end
end
