class User < ApplicationRecord
  has_many :betting_histories, dependent: :destroy

  enum :role, { member: 0, admin: 1 }

  WEEKLY_BUDGET = 10.0
  MIN_BET = 1.0
  MAX_BET = 9.0

  def total_wagered(week = nil)
    scope = week ? betting_histories.where(nfl_week: week) : betting_histories
    scope.sum(:total_stake)
  end

  def total_winnings(week = nil)
    scope = week ? betting_histories.where(nfl_week: week) : betting_histories
    scope.sum(&:winnings)
  end

  def total_profit_loss(week = nil)
    total_winnings(week) - total_wagered(week)
  end

  def win_percentage(week = nil)
    scope = week ? betting_histories.where(nfl_week: week) : betting_histories
    return 0.0 if scope.count == 0
    wins = scope.win.count
    total_decided = scope.where.not(result: :pending).count
    return 0.0 if total_decided == 0
    (wins.to_f / total_decided * 100).round(2)
  end
  
  def win_loss_record(week = nil)
    scope = week ? betting_histories.where(nfl_week: week) : betting_histories
    wins = scope.win.count
    losses = scope.loss.count
    "#{wins}-#{losses}"
  end

  def weekly_budget_used(week)
    betting_histories.where(nfl_week: week).sum(:total_stake)
  end

  def weekly_budget_remaining(week)
    WEEKLY_BUDGET - weekly_budget_used(week)
  end
end
