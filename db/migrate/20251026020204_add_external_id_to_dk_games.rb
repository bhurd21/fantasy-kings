class AddExternalIdToDkGames < ActiveRecord::Migration[8.0]
  def change
    add_column :dk_games, :external_id, :string
    add_index :dk_games, :external_id, unique: true
    
    # Remove the old unique_id constraint and column
    remove_index :dk_games, :unique_id
    remove_column :dk_games, :unique_id, :string
  end
end
