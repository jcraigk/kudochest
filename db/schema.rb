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

ActiveRecord::Schema.define(version: 2020_12_10_014052) do

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
    t.bigint "team_id"
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
    t.bigint "team_id"
    t.bigint "user_id"
    t.string "rid", null: false
    t.string "display_name", null: false
    t.string "real_name", null: false
    t.string "title"
    t.string "slug", null: false
    t.string "avatar_url", null: false
    t.string "reg_token", null: false
    t.boolean "bot_user", null: false
    t.boolean "deleted", null: false
    t.boolean "allow_unprompted_dm", null: false
    t.boolean "infinite_tokens", null: false
    t.integer "tokens_accrued", null: false
    t.decimal "tokens_forfeited", precision: 9, scale: 2, null: false
    t.decimal "karma_received", precision: 9, scale: 2, null: false
    t.decimal "karma_sent", precision: 9, scale: 2, null: false
    t.datetime "last_tip_received_at"
    t.date "streak_date"
    t.integer "streak_count", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "welcomed_at"
    t.datetime "last_tip_sent_at"
    t.integer "karma_claimed", default: 0, null: false
    t.boolean "weekly_report", default: false, null: false
    t.index ["created_at"], name: "index_profiles_on_created_at"
    t.index ["display_name"], name: "index_profiles_on_display_name"
    t.index ["karma_received"], name: "index_profiles_on_karma_received"
    t.index ["karma_sent"], name: "index_profiles_on_karma_sent"
    t.index ["last_tip_received_at"], name: "index_profiles_on_last_tip_received_at"
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
    t.bigint "profile_id"
    t.bigint "subteam_id"
    t.index ["profile_id", "subteam_id"], name: "index_subteam_memberships_on_profile_id_and_subteam_id", unique: true
    t.index ["profile_id"], name: "index_subteam_memberships_on_profile_id"
    t.index ["subteam_id"], name: "index_subteam_memberships_on_subteam_id"
  end

  create_table "subteams", force: :cascade do |t|
    t.bigint "team_id"
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
    t.boolean "limit_karma", null: false
    t.integer "max_karma_per_tip", null: false
    t.integer "token_hour", null: false
    t.string "token_frequency", null: false
    t.integer "token_quantity", null: false
    t.integer "token_max", null: false
    t.integer "member_count", null: false
    t.string "response_mode"
    t.string "log_channel_rid"
    t.string "tip_notes", null: false
    t.string "karma_emoji", null: false
    t.boolean "show_channel", null: false
    t.integer "work_days_mask", null: false
    t.string "week_start_day", null: false
    t.boolean "enable_levels", null: false
    t.string "level_curve", null: false
    t.integer "max_level", null: false
    t.integer "max_level_karma", null: false
    t.datetime "tokens_disbursed_at"
    t.decimal "karma_sent", precision: 9, scale: 2, null: false
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
    t.boolean "notify_tokens_disbursed", null: false
    t.string "platform"
    t.string "app_subteam_rid"
    t.boolean "join_channels", default: false, null: false
    t.boolean "enable_cheers", default: true, null: false
    t.boolean "enable_loot", default: true, null: false
    t.decimal "karma_increment", precision: 4, scale: 2
    t.decimal "emoji_quantity", precision: 4, scale: 2
    t.boolean "split_tip", default: false, null: false
    t.boolean "weekly_report", default: true, null: false
    t.boolean "enable_topics", default: false, null: false
    t.boolean "require_topic", default: false, null: false
    t.boolean "enable_emoji", default: true, null: false
    t.index ["api_key"], name: "index_teams_on_api_key", unique: true
    t.index ["name"], name: "index_teams_on_name"
    t.index ["owner_user_id"], name: "index_teams_on_owner_user_id"
    t.index ["rid"], name: "index_teams_on_rid", unique: true
    t.index ["slug"], name: "index_teams_on_slug", unique: true
    t.index ["token_hour"], name: "index_teams_on_token_hour"
  end

  create_table "tips", force: :cascade do |t|
    t.bigint "contest_id"
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
    t.index "date_trunc('day'::text, created_at)", name: "idx_on_tips_created_at_truncated_to_day"
    t.index ["contest_id"], name: "index_tips_on_contest_id"
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
    t.boolean "subscribe_newsletter", null: false
    t.boolean "admin", null: false
    t.string "theme"
    t.index ["activation_token"], name: "index_users_on_activation_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reg_token"], name: "index_users_on_reg_token", unique: true
    t.index ["remember_me_token"], name: "index_users_on_remember_me_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
  end

  # WARNING: generating adapter-specific definition for tips_after_delete_row_tr() due to a mismatch.
  # either there's a bug in hairtrigger or you've messed up your migrations and/or db :-/
  execute(<<-SQL)
CREATE OR REPLACE FUNCTION public.tips_after_delete_row_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM pg_advisory_xact_lock(1, CAST(OLD.from_profile_id AS int)); UPDATE profiles SET last_tip_sent_at = (SELECT created_at FROM tips WHERE from_profile_id = OLD.from_profile_id ORDER BY created_at DESC LIMIT 1), karma_sent = karma_sent - OLD.quantity WHERE id = OLD.from_profile_id; PERFORM pg_advisory_unlock_all(); PERFORM pg_advisory_xact_lock(1, CAST(OLD.to_profile_id AS int)); UPDATE profiles SET last_tip_received_at = (SELECT created_at FROM tips WHERE to_profile_id = OLD.to_profile_id ORDER BY created_at DESC LIMIT 1), karma_received = karma_received - OLD.quantity WHERE id = OLD.to_profile_id; PERFORM pg_advisory_unlock_all(); PERFORM pg_advisory_xact_lock(2, CAST((SELECT team_id FROM profiles WHERE id = OLD.from_profile_id) AS int)); UPDATE teams SET karma_sent = karma_sent - OLD.quantity WHERE id = (SELECT team_id FROM profiles WHERE id = OLD.to_profile_id); PERFORM pg_advisory_unlock_all();
    RETURN NULL;
END;
$function$
  SQL

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER tips_after_delete_row_tr AFTER DELETE ON \"tips\" FOR EACH ROW EXECUTE FUNCTION tips_after_delete_row_tr()")

  # WARNING: generating adapter-specific definition for tips_after_insert_row_tr() due to a mismatch.
  # either there's a bug in hairtrigger or you've messed up your migrations and/or db :-/
  execute(<<-SQL)
CREATE OR REPLACE FUNCTION public.tips_after_insert_row_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    PERFORM pg_advisory_xact_lock(1, CAST(NEW.from_profile_id AS int)); UPDATE profiles SET last_tip_sent_at = NEW.created_at, karma_sent = karma_sent + NEW.quantity WHERE id = NEW.from_profile_id; PERFORM pg_advisory_unlock_all(); PERFORM pg_advisory_xact_lock(1, CAST(NEW.to_profile_id AS int)); UPDATE profiles SET last_tip_received_at = NEW.created_at, karma_received = karma_received + NEW.quantity WHERE id = NEW.to_profile_id; PERFORM pg_advisory_unlock_all(); PERFORM pg_advisory_xact_lock(2, CAST((SELECT team_id FROM profiles WHERE id = NEW.from_profile_id) AS int)); UPDATE teams SET karma_sent = karma_sent + NEW.quantity WHERE id = (SELECT team_id FROM profiles WHERE id = NEW.to_profile_id); PERFORM pg_advisory_unlock_all();
    RETURN NULL;
END;
$function$
  SQL

  # no candidate create_trigger statement could be found, creating an adapter-specific one
  execute("CREATE TRIGGER tips_after_insert_row_tr AFTER INSERT ON \"tips\" FOR EACH ROW EXECUTE FUNCTION tips_after_insert_row_tr()")

  create_trigger("claims_after_insert_row_tr", :generated => true, :compatibility => 1).
      on("claims").
      after(:insert) do
    "PERFORM pg_advisory_xact_lock(1, CAST(NEW.profile_id AS int)); UPDATE profiles SET karma_claimed = karma_claimed + NEW.price WHERE id = NEW.profile_id; PERFORM pg_advisory_unlock_all();"
  end

  create_trigger("claims_after_delete_row_tr", :generated => true, :compatibility => 1).
      on("claims").
      after(:delete) do
    "PERFORM pg_advisory_xact_lock(1, CAST(OLD.profile_id AS int)); UPDATE profiles SET karma_claimed = karma_claimed - OLD.price WHERE id = OLD.profile_id; PERFORM pg_advisory_unlock_all();"
  end

end
