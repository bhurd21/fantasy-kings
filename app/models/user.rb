class User < ApplicationRecord
  has_many :betting_histories, dependent: :destroy

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
end
