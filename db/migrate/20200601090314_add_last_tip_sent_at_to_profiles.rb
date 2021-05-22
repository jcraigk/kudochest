# frozen_string_literal: true
class AddLastTipSentAtToProfiles < ActiveRecord::Migration[6.0]
  def change
    add_column :profiles, :last_tip_sent_at, :datetime

    drop_trigger('tips_after_insert_row_tr', 'tips', generated: true)
    create_trigger(
      'tips_after_insert_row_tr',
      generated: true,
      compatibility: 1
    )
    .on('tips')
    .after(:insert) do
      <<~SQL.squish
        PERFORM pg_advisory_xact_lock(1, CAST(NEW.from_profile_id AS int));
        UPDATE profiles
          SET
            last_tip_sent_at = NEW.created_at,
            karma_sent = karma_sent + NEW.quantity
          WHERE id = NEW.from_profile_id;
        PERFORM pg_advisory_unlock_all();

        PERFORM pg_advisory_xact_lock(1, CAST(NEW.to_profile_id AS int));
        UPDATE profiles
          SET
            last_tip_received_at = NEW.created_at,
            karma_received = karma_received + NEW.quantity
          WHERE id = NEW.to_profile_id;
        PERFORM pg_advisory_unlock_all();

        PERFORM pg_advisory_xact_lock(2, CAST((SELECT team_id FROM profiles WHERE id = NEW.from_profile_id) AS int));
        UPDATE teams
          SET
            karma_sent = karma_sent + NEW.quantity
          WHERE id = (SELECT team_id FROM profiles WHERE id = NEW.to_profile_id);
        PERFORM pg_advisory_unlock_all();
      SQL
    end

    drop_trigger('tips_after_delete_row_tr', 'tips', generated: true)
    create_trigger(
      'tips_after_delete_row_tr',
      generated: true,
      compatibility: 1
    )
    .on('tips')
    .after(:delete) do
      <<~SQL.squish
        PERFORM pg_advisory_xact_lock(1, CAST(OLD.from_profile_id AS int));
        UPDATE profiles
          SET
            last_tip_sent_at =
              (SELECT created_at FROM tips WHERE from_profile_id = OLD.from_profile_id ORDER BY created_at DESC LIMIT 1),
            karma_sent = karma_sent - OLD.quantity
          WHERE id = OLD.from_profile_id;
        PERFORM pg_advisory_unlock_all();

        PERFORM pg_advisory_xact_lock(1, CAST(OLD.to_profile_id AS int));
        UPDATE profiles
          SET
            last_tip_received_at =
              (SELECT created_at FROM tips WHERE to_profile_id = OLD.to_profile_id ORDER BY created_at DESC LIMIT 1),
            karma_received = karma_received - OLD.quantity
          WHERE id = OLD.to_profile_id;
        PERFORM pg_advisory_unlock_all();

        PERFORM pg_advisory_xact_lock(2, CAST((SELECT team_id FROM profiles WHERE id = OLD.from_profile_id) AS int));
        UPDATE teams
          SET
            karma_sent = karma_sent - OLD.quantity
          WHERE id = (SELECT team_id FROM profiles WHERE id = OLD.to_profile_id);
        PERFORM pg_advisory_unlock_all();
      SQL
    end
  end
end
