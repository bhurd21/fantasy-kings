class AddSportToBettingHistory < ActiveRecord::Migration[8.0]
  def change
    add_column :betting_histories, :is_nfl, :boolean
    add_index :betting_histories, :is_nfl
  end
end
