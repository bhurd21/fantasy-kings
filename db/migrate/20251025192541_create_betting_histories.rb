class CreateBettingHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :betting_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :dk_game, null: true, foreign_key: true  # nullable for backfill
      t.integer :nfl_week
      t.string :bet_type, null: false
      t.text :bet_description
      t.string :line_value
      t.decimal :total_stake, precision: 10, scale: 2
      t.integer :result, default: 0  # enum: pending, win, loss, push
      t.decimal :return_amount, precision: 10, scale: 2, default: 0.0
      t.text :notes

      t.timestamps
    end

    add_index :betting_histories, [:user_id, :created_at]
    add_index :betting_histories, :nfl_week
    add_index :betting_histories, :result
  end
end
