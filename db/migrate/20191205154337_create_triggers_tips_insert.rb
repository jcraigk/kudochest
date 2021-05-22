# frozen_string_literal: true
# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersTipsInsert < ActiveRecord::Migration[6.0]
  def up
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
  end

  def down
    drop_trigger('tips_after_insert_row_tr', 'tips', generated: true)
  end
end
