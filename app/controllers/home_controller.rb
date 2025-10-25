class HomeController < ApplicationController
  def index
    # current_user is already available via helper method from ApplicationController
    @bets = DkGame.all.map do |game|
      {
        id: game.id,
        date: game.commence_time&.strftime('%m/%d %I:%M%p'),
        home_team: game.home_team,
        away_team: game.away_team,
        home_spread: format_spread(game.home_spread_point),
        away_spread: format_spread(game.away_spread_point),
        home_spread_odds: format_odds(game.home_spread_price),
        away_spread_odds: format_odds(game.away_spread_price),
        total: game.total_point,
        total_odds: format_odds(game.over_price),
        under_odds: format_odds(game.under_price),
        home_moneyline: format_odds(game.home_moneyline),
        away_moneyline: format_odds(game.away_moneyline),
        update_time: game.bookmaker_last_update&.strftime('Updated %I:%M%p')
      }
    end
  end

  def create_bet
    selected_bet = params[:selected_bet]
    
    if selected_bet.blank?
      flash[:alert] = "Please select a bet before confirming"
      redirect_to root_path
      return
    end
    
    # Parse the bet selection (format: "game_id_bet_type")
    game_id, bet_type = selected_bet.split('_', 2)
    game = DkGame.find_by(id: game_id)
    
    unless game
      flash[:alert] = "Game not found"
      redirect_to root_path
      return
    end
    
    # Get the line value based on bet type
    line_value = get_line_value(game, bet_type)
    
    # Create betting history record with default stake of 0
    betting_history = current_user.betting_histories.build(
      dk_game: game,
      bet_type: bet_type,
      line_value: line_value,
      total_stake: 0.0,
      result: :pending
    )
    
    if betting_history.save
      flash[:notice] = "Bet submitted successfully! #{betting_history.formatted_description}"
    else
      flash[:alert] = "Error submitting bet: #{betting_history.errors.full_messages.join(', ')}"
    end
    
    redirect_to root_path
  end

  private

  def get_line_value(game, bet_type)
    case bet_type
    when 'home_winner'
      game.home_moneyline
    when 'away_winner'
      game.away_moneyline
    when 'home_spread'
      game.home_spread_price
    when 'away_spread'
      game.away_spread_price
    when 'total_over'
      game.over_price
    when 'total_under'
      game.under_price
    else
      nil
    end
  end

  def format_currency(amount)
    return "$0.00" if amount.nil?
    "$#{sprintf('%.2f', amount)}"
  end

  def format_spread(spread)
    return nil if spread.nil?
    spread > 0 ? "+#{spread}" : spread.to_s
  end

  def format_odds(odds)
    return nil if odds.nil?
    odds > 0 ? "+#{odds}" : odds.to_s
  end
end
