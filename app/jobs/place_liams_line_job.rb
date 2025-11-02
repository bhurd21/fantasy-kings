class PlaceLiamsLineJob < ApplicationJob
  queue_as :default

  def perform
    liam = User.find(4)
    
    # Find the next Detroit Lions game
    lions_game = DkGame.where('LOWER(home_team) LIKE ? OR LOWER(away_team) LIKE ?', '%detroit lions%', '%detroit lions%')
                       .where('commence_time > ?', Time.current)
                       .where(sport: :nfl)
                       .order(:commence_time)
                       .first

    return unless lions_game

    # Check if we already have a pending bet for this game
    existing_bet = liam.betting_histories
                       .where(dk_game: lions_game, result: :pending)
                       .exists?
    
    return if existing_bet

    # Determine bet type (always bet FOR Lions)
    bet_type = lions_game.home_team.match?(/Detroit Lions/i) ? 'home_winner' : 'away_winner'
    line_value = bet_type == 'home_winner' ? lions_game.home_moneyline : lions_game.away_moneyline
    stake = 10.0

    betting_history = liam.betting_histories.build(
      dk_game: lions_game,
      bet_type: bet_type,
      line_value: line_value,
      total_stake: stake,
      result: :pending
    )

    if betting_history.save
      Rails.logger.info "Liam's Line placed: #{betting_history.formatted_description} - Stake: $#{stake.to_i}"
    else
      Rails.logger.error "Failed to place Liam's Line: #{betting_history.errors.full_messages.join(', ')}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "User not found for Liam's Line: #{e.message}"
  rescue => e
    Rails.logger.error "Failed to place Liam's line: #{e.message}"
  end
end
