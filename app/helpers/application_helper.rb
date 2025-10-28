module ApplicationHelper
  include BettingHistoryHelper

  def current_nfl_week
    current_date = Date.current
    year = current_date.year
    season_start = Date.new(year, 9, 1)
    days_since_start = (current_date - season_start).to_i
    week = (days_since_start / 7.0).floor + 1
    [[week, 1].max, 24].min
  end

  def format_currency(amount)
    return "$0.00" if amount.nil?
    amount >= 0 ? "$#{sprintf('%.2f', amount)}" : "-$#{sprintf('%.2f', amount.abs)}"
  end

  def profit_loss_class(amount)
    return 'text-gray-600' if amount == 0
    amount > 0 ? 'text-green-600' : 'text-red-600'
  end

  def result_badge_class(result)
    case result.to_s
    when 'win'
      'bg-green-100 text-green-800'
    when 'loss'
      'bg-red-100 text-red-800'
    when 'push'
      'bg-yellow-100 text-yellow-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def games_last_updated_at
    # Get the most recent update time from bookmaker_last_update or updated_at
    DkGame.maximum(:bookmaker_last_update) || DkGame.maximum(:updated_at)
  end

  def should_show_refresh_banner?
    return false unless current_user
    
    last_updated = games_last_updated_at
    return false unless last_updated
    
    minutes_since = ((Time.current - last_updated) / 1.minute).round
    
    if current_user.admin?
      minutes_since >= 1 # Show after 1 minute
    else
      false # Viewers don't see the banner
    end
  end
end
