class CreateDkGames < ActiveRecord::Migration[7.0]
  def change
    create_table :dk_games do |t|
      t.integer :sport, null: false, default: 0
      t.datetime :commence_time
      t.string :home_team
      t.string :away_team
      t.datetime :bookmaker_last_update
      t.integer :home_moneyline
      t.integer :away_moneyline
      t.float :home_spread_point
      t.integer :home_spread_price
      t.float :away_spread_point
      t.integer :away_spread_price
      t.float :total_point
      t.integer :over_price
      t.integer :under_price
      t.string :unique_id, null: false

      t.timestamps
    end

    add_index :dk_games, :unique_id, unique: true
  end
end
