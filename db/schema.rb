# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_26_175357) do
  create_table "betting_histories", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "dk_game_id"
    t.integer "nfl_week"
    t.string "bet_type", null: false
    t.text "bet_description"
    t.string "line_value"
    t.decimal "total_stake", precision: 10, scale: 2
    t.integer "result", default: 0
    t.decimal "return_amount", precision: 10, scale: 2, default: "0.0"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dk_game_id"], name: "index_betting_histories_on_dk_game_id"
    t.index ["nfl_week"], name: "index_betting_histories_on_nfl_week"
    t.index ["result"], name: "index_betting_histories_on_result"
    t.index ["user_id", "created_at"], name: "index_betting_histories_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_betting_histories_on_user_id"
  end

  create_table "dk_games", force: :cascade do |t|
    t.integer "sport", default: 0, null: false
    t.datetime "commence_time"
    t.string "home_team"
    t.string "away_team"
    t.datetime "bookmaker_last_update"
    t.integer "home_moneyline"
    t.integer "away_moneyline"
    t.float "home_spread_point"
    t.integer "home_spread_price"
    t.float "away_spread_point"
    t.integer "away_spread_price"
    t.float "total_point"
    t.integer "over_price"
    t.integer "under_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index ["external_id"], name: "index_dk_games_on_external_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
  end

  add_foreign_key "betting_histories", "dk_games"
  add_foreign_key "betting_histories", "users"
end
