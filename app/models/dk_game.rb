class DkGame < ApplicationRecord
  enum :sport, { nfl: 0, ncaaf: 1 }
  
  has_many :betting_histories, dependent: :nullify

  validates :external_id, presence: true, uniqueness: true
  validates :sport, presence: true
  validates :commence_time, presence: true
  validates :home_team, :away_team, presence: true
end
