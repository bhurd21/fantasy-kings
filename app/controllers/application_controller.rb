class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :require_authentication
  
  private
  
  def require_authentication
    unless current_user
      redirect_to sign_in_path, alert: "Please sign in to continue."
    end
  end
  
  def current_user
    return nil unless session[:user_id]
    @current_user ||= User.find_by(id: session[:user_id])
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end
  
  def current_nfl_week
    current_time = Time.current.in_time_zone('Eastern Time (US & Canada)')
    year = current_time.year
    
    # Weeks will change on Tuesday at 3 AM EST
    season_start = Time.zone.parse("#{year}-09-02 03:00:00")
    
    hours_since_start = ((current_time - season_start) / 1.hour).floor
    days_since_start = (hours_since_start / 24.0).floor
    week = (days_since_start / 7.0).floor + 1
    [[week, 1].max, 24].min
  end
  
  helper_method :current_user, :current_nfl_week
end
