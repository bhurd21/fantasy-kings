module HomeHelper
  def time_ago_in_words_short(time)
    return unless time
    
    seconds_diff = (Time.current - time).to_i.abs
    
    case seconds_diff
    when 0..59
      "just now"
    when 60..3599
      minutes = (seconds_diff / 60).round
      "#{minutes}m ago"
    when 3600..86399
      hours = (seconds_diff / 3600).round
      "#{hours}h ago"
    when 86400..604799
      days = (seconds_diff / 86400).round
      "#{days}d ago"
    else
      weeks = (seconds_diff / 604800).round
      "#{weeks}w ago"
    end
  end

  def format_bet_commence_time(time)
    return unless time
    { date: time.strftime('%a %b %-d'), time: time.strftime('%-l:%M %p %Z') }
  end
end
