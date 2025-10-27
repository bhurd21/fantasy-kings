module BettingHistoryHelper
  def self.format_bet_description(betting_history)
    Rails.logger.info "#{betting_history.inspect}"
    return betting_history.bet_description if betting_history.bet_description.present?
    
    game = betting_history.dk_game
    bet_type = betting_history.bet_type
    
    return "Unknown bet" unless game && bet_type

    case bet_type
    when 'home_moneyline', 'home_winner'
      "#{game.home_team} ML"
    when 'away_moneyline', 'away_winner'
      "#{game.away_team} ML"
    when 'home_spread'
      spread = game.home_spread_point
      spread_str = spread > 0 ? "+#{spread}" : spread.to_s
      "#{game.home_team} #{spread_str}"
    when 'away_spread'
      spread = game.away_spread_point
      spread_str = spread > 0 ? "+#{spread}" : spread.to_s
      "#{game.away_team} #{spread_str}"
    when 'total_over', 'over'
      "O #{game.total_point} #{game.away_team} vs #{game.home_team}"
    when 'total_under', 'under'
      "U #{game.total_point} #{game.away_team} vs #{game.home_team}"
    else
      "#{game.home_team} vs #{game.away_team} - #{bet_type.humanize}"
    end
  end

  def self.format_line(bet_type, line_value)
    return line_value if line_value.blank?
    
    case bet_type
    when 'home_moneyline', 'away_moneyline', 'moneyline'
      format_odds(line_value)
    when 'home_spread', 'away_spread', 'spread'
      odds = line_value.to_i
      format_odds(odds)
    when 'over', 'under', 'total_over', 'total_under'
      odds = line_value.to_i
      format_odds(odds)
    else
      # For any other bet type, still format as odds if it's a number
      if line_value.to_s.match?(/^-?\d+$/)
        format_odds(line_value)
      else
        line_value
      end
    end
  end

  def self.format_odds(odds)
    return nil if odds.nil? || odds == 0
    
    odds = odds.to_i
    if odds > 0
      "+#{odds}"
    else
      odds.to_s
    end
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
end
