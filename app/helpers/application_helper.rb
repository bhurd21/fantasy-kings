module ApplicationHelper
  include BettingHistoryHelper

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
