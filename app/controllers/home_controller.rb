class HomeController < ApplicationController
  def index
    @current_user = User.find(session[:user_id]) if session[:user_id]
    @user_info = session[:user_info] if session[:user_info]
  end
end
