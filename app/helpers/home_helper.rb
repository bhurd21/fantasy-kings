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
    
    # Parse the time if it's a string
    parsed_time = time.is_a?(String) ? Time.parse(time) : time
    
    # Convert to CST and EST for display
    cst_time = parsed_time.in_time_zone('Central Time (US & Canada)')
    
    # Format date as "Day, Mon DD" using CST time for consistency
    date_line = cst_time.strftime('%b %-d')
    
    # Format times as "H:MM am/pm cst"
    cst_formatted = cst_time.strftime('%-l:%M %P') + ' cst'
    
    { date: date_line, time: cst_formatted }
  end
end
