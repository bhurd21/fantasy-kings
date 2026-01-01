class BettingHistory < ApplicationRecord
  belongs_to :user
  belongs_to :dk_game, optional: true  # optional for backfill data

  enum :result, { pending: 0, win: 1, loss: 2, push: 3 }

  validates :total_stake, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :nfl_week, presence: true, numericality: { in: 1..28 }

  before_validation :set_nfl_week, on: :create
  before_create :set_bet_description

  scope :recent, -> { order(created_at: :desc) }
  scope :by_week, ->(week) { where(nfl_week: week) }
  scope :by_result, ->(result) { where(result: result) }

  def formatted_line
    BettingHistoryHelper.format_line(bet_type, line_value)
  end

  def formatted_description
    BettingHistoryHelper.format_bet_description(self)
  end

  # Winnings calculation: total amount returned (stake + profit for win, stake for push, 0 for loss)
  def winnings
    return 0.0 if pending? || loss?
    return total_stake.to_f if push?
    
    # For a win, calculate: stake + (stake * payout based on odds)
    # Formula from Google Sheets: TRUNC(IF(result = "Win", IF(line < 0, stake + (stake * 100 / -line), stake + (stake / 100 * line)), IF(result = "Push", stake, 0)), 2)
    if win?
      line = line_value.to_f
      stake = total_stake.to_f
      
      if line < 0
        stake + (stake * 100 / -line)
      else
        stake + (stake / 100 * line)
      end
    else
      0.0
    end
  end

  def profit_loss
    return 0.0 if pending?
    return -total_stake.to_f if loss?
    return 0.0 if push?
    winnings - total_stake.to_f
  end

  def roi_percentage
    return 0.0 if total_stake == 0
    (profit_loss / total_stake * 100).round(2)
  end

  private

  def set_nfl_week
    self.nfl_week ||= calculate_current_nfl_week
  end

  def set_bet_description
    self.bet_description ||= BettingHistoryHelper.format_bet_description(self)
  end

  def calculate_current_nfl_week
    # NFL season typically starts first Sunday after Labor Day (around Sept 1)
    current_date = Date.current
    year = current_date.year
    
    # NFL season start (September 3rd)
    season_start = Date.new(year, 9, 3)
    
    # Calculate week number
    days_since_start = (current_date - season_start).to_i
    week = (days_since_start / 7.0).floor + 1
    
    # Clamp between 1 and 24
    [[week, 1].max, 24].min
  end
end
