class DkGame < ApplicationRecord
  enum :sport, { nfl: 0, ncaaf: 1 }

  validates :unique_id, presence: true, uniqueness: true
  validates :sport, presence: true
  validates :commence_time, presence: true
  validates :home_team, :away_team, presence: true

  before_validation :set_unique_id

  private

  def set_unique_id
    # don't overwrite if already set and bail if required fields missing
    return if unique_id.present? || home_team.blank? || away_team.blank? || commence_time.blank?

    # Normalize teams and date to create a stable unique id
    home = home_team.to_s.strip
    away = away_team.to_s.strip
    date = commence_time.to_date.to_s rescue nil
    self.unique_id = [home, away, date].join("|")
  end
end
