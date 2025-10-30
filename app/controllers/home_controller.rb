class HomeController < ApplicationController
  before_action :require_user, except: [:index]

  def index
    return redirect_to sign_in_path unless current_user
    
    # If user is a viewer, show different content
    if current_user.viewer?
      @bets = DkGame.none
      return
    end
    current_time = Time.current
    # Show games in current_nfl_week that have not started yet
    @bets = DkGame.where('commence_time > ?', current_time)
                  .select { |game| same_nfl_week?(game.commence_time) }
                  .sort_by(&:commence_time)
                  .map do |game|
      {
        id: game.id,
        date: game.commence_time.in_time_zone(Time.zone),
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
        update_time: game.bookmaker_last_update
      }
    end
  end

  def create_bet
    # Prevent viewers from betting
    if current_user.viewer?
      flash[:alert] = "Viewers cannot place bets. Please contact an admin for access."
      redirect_to root_path
      return
    end
    
    selected_bet = params[:selected_bet]
    stake = params[:stake].to_f
    
    if selected_bet.blank?
      flash[:alert] = "Please select a bet before confirming"
      redirect_to root_path
      return
    end
    
    # Validate stake amount
    if stake < User::MIN_BET
      flash[:alert] = "Minimum bet is $#{User::MIN_BET}"
      redirect_to root_path
      return
    end
    
    if stake > User::MAX_BET
      flash[:alert] = "Maximum bet is $#{User::MAX_BET}"
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
    
    # Create betting history record with user's stake
    betting_history = current_user.betting_histories.build(
      dk_game: game,
      bet_type: bet_type,
      line_value: line_value,
      total_stake: stake,
      result: :pending
    )
    
    # Check weekly budget
    week = betting_history.nfl_week || betting_history.send(:calculate_current_nfl_week)
    budget_remaining = current_user.weekly_budget_remaining(week)
    
    if stake > budget_remaining
      flash[:alert] = "Insufficient weekly budget. You have $#{sprintf('%.2f', budget_remaining)} remaining for week #{week}."
      redirect_to root_path
      return
    end
    
    if betting_history.save
      flash[:notice] = "Bet submitted successfully! #{betting_history.formatted_description} - Stake: #{format_currency(stake)}"
    else
      flash[:alert] = "Error submitting bet: #{betting_history.errors.full_messages.join(', ')}"
    end
    
    redirect_to root_path
  end

  def week
    @week = params[:week].to_i
    @betting_histories = BettingHistory.includes(:user, :dk_game)
                                       .joins(:user)
                                       .where(nfl_week: @week)
                                       .where.not(users: { role: :viewer })
                                       .order(created_at: :desc)
    
    # Group betting histories by user
    @user_bets = @betting_histories.group_by(&:user)
    
    # Sort bets within each user group by result order: Win, Pending, Push, Loss
    result_order = { 'win' => 1, 'push' => 2, 'pending' => 3, 'loss' => 4 }
    @user_bets.each do |user, bets|
      @user_bets[user] = bets.sort_by { |bet| result_order[bet.result] || 5 }
    end
    
    # Calculate stats for each user and sort by winnings desc
    @user_stats = {}
    @user_bets.each do |user, bets|
      @user_stats[user.id] = {
        total_spent: bets.sum(&:total_stake),
        total_winnings: bets.sum(&:winnings)
      }
    end
    
    # Sort users by winnings (descending)
    @user_bets = @user_bets.sort_by { |user, _| -@user_stats[user.id][:total_winnings] }.to_h
  end

  def profile
    @user = current_user
    @current_week = current_nfl_week
    @selected_week = params[:week]&.to_i || @current_week
    
    # Week stats
    @week_record = @user.win_loss_record(@selected_week)
    @week_winnings = @user.total_winnings(@selected_week)
    @week_spent = @user.total_wagered(@selected_week)
    
    # Season stats
    @season_record = @user.win_loss_record
    @season_winnings = @user.total_winnings
    @season_spent = @user.total_wagered
    
    @betting_histories = current_user.betting_histories.recent.includes(:dk_game)
  end

  def user_profile
    @user = User.find(params[:id])
    @current_week = current_nfl_week
    @selected_week = params[:week]&.to_i || @current_week
    
    # Week stats
    @week_record = @user.win_loss_record(@selected_week)
    @week_winnings = @user.total_winnings(@selected_week)
    @week_spent = @user.total_wagered(@selected_week)
    
    # Season stats
    @season_record = @user.win_loss_record
    @season_winnings = @user.total_winnings
    @season_spent = @user.total_wagered
    
    @betting_histories = @user.betting_histories.recent.includes(:dk_game)
    render :profile
  end

  def settings
    # Placeholder for settings page
  end

  def leaderboard
    # Get all users with their betting histories (exclude viewers)
    users = User.includes(:betting_histories).where.not(role: :viewer)
    
    # Calculate stats for each user
    @leaderboard = users.map do |user|
      {
        user: user,
        winnings: user.total_winnings,
        stake: user.total_wagered
      }
    end
    
    # Sort by winnings descending
    @leaderboard.sort_by! { |entry| -entry[:winnings] }
  end

  def weekly_budget
    week = params[:week].to_i
    used = current_user.weekly_budget_used(week).to_f
    remaining = current_user.weekly_budget_remaining(week).to_f
    
    Rails.logger.info "Weekly budget request - User: #{current_user.id}, Week: #{week}, Used: #{used}, Remaining: #{remaining}"
    
    render json: {
      week: week,
      budget: User::WEEKLY_BUDGET,
      used: used,
      remaining: remaining,
      min_bet: User::MIN_BET,
      max_bet: User::MAX_BET
    }
  end

  def update_bet_result
    unless current_user&.admin?
      render json: { success: false, errors: ['Unauthorized access'] }, status: :unauthorized
      return
    end

    betting_history = BettingHistory.find(params[:id])
    result_value = params[:result]
    
    Rails.logger.info "Updating bet #{params[:id]} with result: #{result_value}"
    
    if betting_history.update(result: result_value)
      Rails.logger.info "Successfully updated bet to: #{betting_history.result}"
      render json: { success: true, result: betting_history.result }
    else
      Rails.logger.error "Failed to update bet: #{betting_history.errors.full_messages}"
      render json: { success: false, errors: betting_history.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def refresh_games
    unless current_user&.admin? || current_user&.player?
      render json: { success: false, errors: ['Unauthorized access'] }, status: :unauthorized
      return
    end

    begin
      # Run synchronously for immediate feedback
      UpdateDkGamesJob.perform_now
      render json: { success: true, message: 'Games updated successfully' }
    rescue => e
      Rails.logger.error "Failed to update games: #{e.message}"
      render json: { success: false, errors: [e.message] }, status: :unprocessable_entity
    end
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

  def require_user
    redirect_to sign_in_path unless current_user
  end
end
