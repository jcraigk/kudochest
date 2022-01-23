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

ActiveRecord::Schema.define(version: 2022_01_23_001427) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "authentications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["provider", "uid"], name: "index_authentications_on_provider_and_uid"
  end

  create_table "channels", force: :cascade do |t|
    t.integer "team_id"
    t.string "rid", null: false
    t.string "name", null: false
    t.boolean "shared", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "team_id"], name: "index_channels_on_name_and_team_id", unique: true
    t.index ["rid", "team_id"], name: "index_channels_on_rid_and_team_id", unique: true
    t.index ["team_id"], name: "index_channels_on_team_id"
  end

  create_table "claims", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "profile_id"
    t.uuid "reward_id"
    t.integer "price"
    t.string "fulfillment_key"
    t.datetime "fulfilled_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_claims_on_created_at"
    t.index ["profile_id", "reward_id", "fulfillment_key"], name: "index_claims_on_profile_id_and_reward_id_and_fulfillment_key", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "team_id"
    t.integer "user_id"
    t.string "rid", null: false
    t.string "display_name", null: false
    t.string "real_name", null: false
    t.string "title"
    t.string "slug", null: false
    t.string "avatar_url", null: false
    t.string "reg_token", null: false
    t.boolean "bot_user", null: false
    t.boolean "deleted", null: false
    t.boolean "allow_dm", null: false
    t.boolean "infinite_tokens", null: false
    t.integer "tokens_accrued", null: false
    t.decimal "tokens_forfeited", precision: 9, scale: 2, null: false
    t.decimal "points_received", precision: 9, scale: 2, null: false
    t.decimal "points_sent", precision: 9, scale: 2, null: false
    t.datetime "last_tip_received_at"
    t.date "streak_date"
    t.integer "streak_count", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "welcomed_at"
    t.datetime "last_tip_sent_at"
    t.integer "points_claimed", default: 0, null: false
    t.boolean "weekly_report", default: true, null: false
    t.boolean "announce_tip_sent", default: true, null: false
    t.boolean "announce_tip_received", default: true, null: false
    t.boolean "share_history", default: true, null: false
    t.index ["created_at"], name: "index_profiles_on_created_at"
    t.index ["display_name"], name: "index_profiles_on_display_name"
    t.index ["last_tip_received_at"], name: "index_profiles_on_last_tip_received_at"
    t.index ["points_received"], name: "index_profiles_on_points_received"
    t.index ["points_sent"], name: "index_profiles_on_points_sent"
    t.index ["reg_token"], name: "index_profiles_on_reg_token", unique: true
    t.index ["rid", "team_id"], name: "index_profiles_on_rid_and_team_id", unique: true
    t.index ["slug"], name: "index_profiles_on_slug", unique: true
    t.index ["team_id"], name: "index_profiles_on_team_id"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "rewards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "team_id"
    t.string "name"
    t.text "description"
    t.integer "quantity"
    t.integer "price"
    t.boolean "auto_fulfill", null: false
    t.string "fulfillment_keys"
    t.boolean "active", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["team_id", "name"], name: "index_rewards_on_team_id_and_name", unique: true
  end

  create_table "subteam_memberships", id: false, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "subteam_id"
    t.index ["profile_id", "subteam_id"], name: "index_subteam_memberships_on_profile_id_and_subteam_id", unique: true
    t.index ["profile_id"], name: "index_subteam_memberships_on_profile_id"
    t.index ["subteam_id"], name: "index_subteam_memberships_on_subteam_id"
  end

  create_table "subteams", force: :cascade do |t|
    t.integer "team_id"
    t.string "rid", null: false
    t.string "name", null: false
    t.string "description"
    t.string "handle"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["handle", "team_id"], name: "index_subteams_on_handle_and_team_id", unique: true
    t.index ["name", "team_id"], name: "index_subteams_on_name_and_team_id", unique: true
    t.index ["rid", "team_id"], name: "index_subteams_on_rid_and_team_id", unique: true
    t.index ["team_id"], name: "index_subteams_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.integer "owner_user_id"
    t.string "rid", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "avatar_url", null: false
    t.string "api_key", null: false
    t.boolean "throttle_tips", null: false
    t.integer "max_points_per_tip", null: false
    t.integer "action_hour", null: false
    t.string "token_frequency", null: false
    t.integer "token_quantity", null: false
    t.integer "token_max", null: false
    t.integer "member_count", null: false
    t.string "response_mode"
    t.string "log_channel_rid"
    t.string "tip_notes", null: false
    t.string "tip_emoji", null: false
    t.boolean "show_channel", null: false
    t.integer "work_days_mask", null: false
    t.string "week_start_day", null: false
    t.boolean "enable_levels", null: false
    t.string "level_curve", null: false
    t.integer "max_level", null: false
    t.integer "max_level_points", null: false
    t.datetime "tokens_disbursed_at"
    t.decimal "points_sent", precision: 9, scale: 2, null: false
    t.boolean "active", null: false
    t.boolean "enable_streaks", null: false
    t.integer "streak_duration", null: false
    t.integer "streak_reward", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "app_profile_rid"
    t.string "time_zone", default: "UTC", null: false
    t.string "response_theme"
    t.boolean "installed", null: false
    t.boolean "enable_fast_ack", null: false
    t.boolean "notify_tokens", null: false
    t.string "platform"
    t.string "app_subteam_rid"
    t.boolean "join_channels", default: false, null: false
    t.boolean "enable_cheers", default: true, null: false
    t.boolean "enable_loot", default: true, null: false
    t.decimal "tip_increment", precision: 4, scale: 2
    t.decimal "emoji_quantity", precision: 4, scale: 2
    t.boolean "split_tip", default: false, null: false
    t.boolean "weekly_report", default: true, null: false
    t.boolean "enable_topics", default: false, null: false
    t.boolean "require_topic", default: false, null: false
    t.boolean "enable_emoji", default: true, null: false
    t.string "ditto_emoji"
    t.string "hint_frequency", default: "never", null: false
    t.string "hint_channel_rid"
    t.datetime "hint_posted_at"
    t.boolean "show_note", default: true, null: false
    t.index ["action_hour"], name: "index_teams_on_action_hour"
    t.index ["api_key"], name: "index_teams_on_api_key", unique: true
    t.index ["name"], name: "index_teams_on_name"
    t.index ["owner_user_id"], name: "index_teams_on_owner_user_id"
    t.index ["rid"], name: "index_teams_on_rid", unique: true
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  create_table "tips", force: :cascade do |t|
    t.integer "from_profile_id", null: false
    t.integer "to_profile_id", null: false
    t.string "source", null: false
    t.string "from_channel_rid"
    t.string "from_channel_name"
    t.decimal "quantity", precision: 9, scale: 2, null: false
    t.string "event_ts", null: false
    t.string "note"
    t.string "response_ts"
    t.string "response_channel_rid"
    t.string "to_channel_rid"
    t.string "to_channel_name"
    t.string "to_subteam_rid"
    t.string "to_subteam_handle"
    t.datetime "created_at"
    t.boolean "to_everyone", default: false
    t.uuid "topic_id"
    t.string "chat_permalink"
    t.index "date_trunc('day'::text, created_at)", name: "idx_on_tips_created_at_truncated_to_day"
    t.index ["created_at"], name: "index_tips_on_created_at"
    t.index ["event_ts", "to_profile_id"], name: "index_tips_on_event_ts_and_to_profile_id", unique: true
    t.index ["from_profile_id"], name: "index_tips_on_from_profile_id"
    t.index ["source"], name: "index_tips_on_source"
    t.index ["to_profile_id"], name: "index_tips_on_to_profile_id"
    t.index ["topic_id"], name: "index_tips_on_topic_id"
  end

  create_table "topics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "team_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "keyword", null: false
    t.string "emoji"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["team_id", "emoji"], name: "index_topics_on_team_id_and_emoji", unique: true
    t.index ["team_id", "keyword"], name: "index_topics_on_team_id_and_keyword", unique: true
    t.index ["team_id", "name"], name: "index_topics_on_team_id_and_name", unique: true
    t.index ["team_id"], name: "index_topics_on_team_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.integer "access_count_to_reset_password_page", default: 0
    t.string "activation_state"
    t.string "activation_token"
    t.datetime "activation_token_expires_at"
    t.string "reg_token", null: false
    t.boolean "admin", null: false
    t.string "theme"
    t.index ["activation_token"], name: "index_users_on_activation_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reg_token"], name: "index_users_on_reg_token", unique: true
    t.index ["remember_me_token"], name: "index_users_on_remember_me_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
  end

end
