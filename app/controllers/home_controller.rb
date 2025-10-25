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
    
    if selected_bet.present?
      # Parse the bet selection (format: "game_id_bet_type")
      game_id, bet_type = selected_bet.split('_', 2)
      game = DkGame.find_by(id: game_id)
      
      if game
        # For now, just log the bet submission
        Rails.logger.info "BET SUBMISSION - User: #{current_user.name} (#{current_user.id}), Game: #{game.home_team} vs #{game.away_team}, Bet: #{bet_type}, Time: #{Time.current}"
        
        flash[:notice] = "Bet submitted successfully! (#{bet_type} for #{game.home_team} vs #{game.away_team}; #{game.inspect})"
      else
        flash[:alert] = "Game not found"
      end
    else
      flash[:alert] = "Please select a bet before confirming"
    end
    
    redirect_to root_path
  end

  private

  def format_spread(spread)
    return nil if spread.nil?
    spread > 0 ? "+#{spread}" : spread.to_s
  end

  def format_odds(odds)
    return nil if odds.nil?
    odds > 0 ? "+#{odds}" : odds.to_s
  end
end
