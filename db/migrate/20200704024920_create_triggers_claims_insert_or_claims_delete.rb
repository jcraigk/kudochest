# frozen_string_literal: true
# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersClaimsInsertOrClaimsDelete < ActiveRecord::Migration[6.0]
  def up
    create_trigger('claims_after_insert_row_tr', generated: true, compatibility: 1).
        on('claims').
        after(:insert) do
      <<~SQL.squish
        PERFORM pg_advisory_xact_lock(1, CAST(NEW.profile_id AS int));
        UPDATE profiles
          SET karma_claimed = karma_claimed + NEW.price
          WHERE id = NEW.profile_id;
        PERFORM pg_advisory_unlock_all();
      SQL
    end

    create_trigger('claims_after_delete_row_tr', generated: true, compatibility: 1).
        on('claims').
        after(:delete) do
      <<~SQL.squish
        PERFORM pg_advisory_xact_lock(1, CAST(OLD.profile_id AS int));
        UPDATE profiles
          SET karma_claimed = karma_claimed - OLD.price
          WHERE id = OLD.profile_id;
        PERFORM pg_advisory_unlock_all();
      SQL
    end
  end

  def down
    drop_trigger('claims_after_insert_row_tr', 'claims', generated: true)
    drop_trigger('claims_after_delete_row_tr', 'claims', generated: true)
  end
end
