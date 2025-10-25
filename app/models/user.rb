class User < ApplicationRecord
  has_many :betting_histories, dependent: :destroy

  enum :role, { member: 0, admin: 1 }

  WEEKLY_BUDGET = 10.0
  MIN_BET = 1.0
  MAX_BET = 9.0

  def total_wagered
    betting_histories.sum(:total_stake)
  end

  def total_profit_loss
    betting_histories.sum(&:profit_loss)
  end

  def win_percentage
    return 0.0 if betting_histories.count == 0
    wins = betting_histories.win.count
    total_decided = betting_histories.where.not(result: :pending).count
    return 0.0 if total_decided == 0
    (wins.to_f / total_decided * 100).round(2)
  end

  def weekly_budget_used(week)
    betting_histories.where(nfl_week: week).sum(:total_stake)
  end

  def weekly_budget_remaining(week)
    WEEKLY_BUDGET - weekly_budget_used(week)
  end
end
