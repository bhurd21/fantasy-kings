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

  def format_bet_commence_time_compact(time)
    return unless time
    # Convert to Central Time and format as "Sat 11:00"
    cst_time = time.in_time_zone('Central Time (US & Canada)')
    cst_time.strftime('%a %-l:%M%p')
  end

  def sport_icon(game, result = 'pending')
    return '' unless game

    icon_class = if game.nfl?
      'fa-shield'
    elsif game.ncaaf?
      'fa-football'
    else
      return ''
    end

    color_class = case result.to_s
    when 'win'
      'sport-icon-win'
    when 'loss'
      'sport-icon-loss'
    when 'push'
      'sport-icon-push'
    else
      'sport-icon-pending'
    end

    "<i class=\"fa-solid #{icon_class} sport-icon #{color_class}\"></i>".html_safe
  end
end
