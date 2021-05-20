# frozen_string_literal: true
# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersTipsDelete < ActiveRecord::Migration[6.0]
  def up
    create_trigger(
      'tips_after_delete_row_tr',
      generated: true,
      compatibility: 1
    )
    .on('tips')
    .after(:delete) do
      <<-SQL_ACTIONS
PERFORM pg_advisory_xact_lock(1, CAST(OLD.from_profile_id AS int));
UPDATE profiles
  SET
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
      SQL_ACTIONS
    end
  end

  def down
    drop_trigger('tips_after_delete_row_tr', 'tips', generated: true)
  end
end
