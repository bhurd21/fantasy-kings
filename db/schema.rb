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

ActiveRecord::Schema[8.0].define(version: 2025_10_25_170000) do
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
    t.string "unique_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unique_id"], name: "index_dk_games_on_unique_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
