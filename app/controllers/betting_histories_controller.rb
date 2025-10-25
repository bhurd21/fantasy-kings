class BettingHistoriesController < ApplicationController
  before_action :require_user
  
  def index
    @betting_histories = current_user.betting_histories.recent.includes(:dk_game)
    @total_wagered = current_user.total_wagered
    @total_profit_loss = current_user.total_profit_loss
    @win_percentage = current_user.win_percentage
    
    # Filter by week if specified
    if params[:week].present?
      @betting_histories = @betting_histories.by_week(params[:week])
    end
    
    # Filter by result if specified
    if params[:result].present?
      @betting_histories = @betting_histories.by_result(params[:result])
    end
    
    @betting_histories = @betting_histories.page(params[:page]).per(20)
  end

  def show
    @betting_history = current_user.betting_histories.find(params[:id])
  end

  def create
    @betting_history = current_user.betting_histories.build(betting_history_params)
    
    if @betting_history.save
      flash[:notice] = "Bet submitted successfully!"
      redirect_to root_path
    else
      flash[:alert] = "Error submitting bet: #{@betting_history.errors.full_messages.join(', ')}"
      redirect_to root_path
    end
  end

  def update
    @betting_history = current_user.betting_histories.find(params[:id])
    
    if @betting_history.update(betting_history_params)
      flash[:notice] = "Bet updated successfully!"
      redirect_to betting_histories_path
    else
      flash[:alert] = "Error updating bet: #{@betting_history.errors.full_messages.join(', ')}"
      redirect_to betting_history_path(@betting_history)
    end
  end

  private

  def betting_history_params
    params.require(:betting_history).permit(:dk_game_id, :bet_type, :line_value, :result, :return_amount, :notes)
  end

  def require_user
    redirect_to sign_in_path unless current_user
  end
end
