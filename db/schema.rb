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

ActiveRecord::Schema[7.2].define(version: 2026_01_11_133000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "icon"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "feelings", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_feelings_on_name", unique: true
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "habit_id", null: false
    t.integer "goal_unit", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "frequency", default: 0, null: false
    t.integer "amount"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["goal_unit"], name: "index_goals_on_goal_unit"
    t.index ["habit_id"], name: "index_goals_on_habit_id"
    t.index ["status"], name: "index_goals_on_status"
    t.index ["user_id", "goal_unit", "status"], name: "index_goals_on_user_id_and_goal_unit_and_status"
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "habit_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "habit_id", null: false
    t.bigint "goal_id", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.integer "performed_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["goal_id"], name: "index_habit_logs_on_goal_id"
    t.index ["habit_id"], name: "index_habit_logs_on_habit_id"
    t.index ["started_at"], name: "index_habit_logs_on_started_at"
    t.index ["user_id", "habit_id"], name: "index_habit_logs_on_user_id_and_habit_id"
    t.index ["user_id"], name: "index_habit_logs_on_user_id"
  end

  create_table "habits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "archived_at"
    t.index ["category_id"], name: "index_habits_on_category_id"
    t.index ["user_id"], name: "index_habits_on_user_id"
  end

  create_table "mood_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "mood_id", null: false
    t.datetime "recorded_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "feeling_id"
    t.integer "timing"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "habit_log_id"
    t.index ["feeling_id"], name: "index_mood_logs_on_feeling_id"
    t.index ["habit_log_id"], name: "index_mood_logs_on_habit_log_id"
    t.index ["mood_id"], name: "index_mood_logs_on_mood_id"
    t.index ["user_id"], name: "index_mood_logs_on_user_id"
  end

  create_table "moods", force: :cascade do |t|
    t.integer "score", null: false
    t.string "label", null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label"], name: "index_moods_on_label", unique: true
    t.index ["score"], name: "index_moods_on_score", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "provider"
    t.string "uid"
    t.boolean "onboarding_completed", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "goals", "habits"
  add_foreign_key "goals", "users"
  add_foreign_key "habit_logs", "goals"
  add_foreign_key "habit_logs", "habits"
  add_foreign_key "habit_logs", "users"
  add_foreign_key "habits", "categories"
  add_foreign_key "habits", "users"
  add_foreign_key "mood_logs", "feelings"
  add_foreign_key "mood_logs", "habit_logs"
  add_foreign_key "mood_logs", "moods"
  add_foreign_key "mood_logs", "users"
end
