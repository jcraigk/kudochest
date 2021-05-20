# frozen_string_literal: true
class Tip < ApplicationRecord
  extend Enumerize
  include TipDecorator

  enumerize :source, in: %w[auto modal plusplus reaction reply streak import]

  belongs_to :from_profile,
             class_name: 'Profile',
             inverse_of: :tips_sent
  belongs_to :to_profile,
             class_name: 'Profile',
             inverse_of: :tips_received
  belongs_to :topic, optional: true

  validates :from_profile_id, presence: true
  validates :to_profile_id, presence: true
  validates :note, length: { maximum: App.max_note_length }
  validates :topic_id,
            presence: { message: I18n.t('tips.topic_presence', url: "#{App.base_url}/topic-list") },
            if: :require_topic?
  # Commented for performance (rescue RecordNotUnique and save a query)
  # validates :event_ts, uniqueness: { scope: %i[type to_profile_id] }
  validates_with QuantityValidator
  validates_with RecipientNotABotValidator
  validates_with RecipientNotDeletedValidator
  validates_with RecipientNotSelfValidator

  after_destroy_commit :delete_chat_response

  scope :undoable, lambda {
    where(source: %w[modal plusplus reaction reply streak])
      .where('created_at > ?', Time.current - App.undo_cutoff)
      .order(created_at: :desc)
  }
  scope :search_notes, lambda { |term|
    where('lower(tips.note) LIKE lower(?)', "%#{sanitize_sql_like(term)}%")
  }

  # From console:
  # Zeitwerk::Loader.eager_load_all
  # Rails.application.load_tasks
  # Rake::Task['db:generate_trigger_migration'].invoke
  trigger.after(:insert) do
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

  trigger.after(:delete) do
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

  def topic_name
    topic&.name || 'None'
  end

  private

  def delete_chat_response
    return if response_channel_rid.blank? || response_ts.blank?
    send("delete_#{from_profile.team.platform}_response")
  end

  def delete_slack_response
    from_profile.team.slack_client.chat_delete(channel: response_channel_rid, ts: response_ts)
  rescue Slack::Web::Api::Errors::SlackError
    nil # `message_not_found` - many tips may be associated with same ts
  end

  def delete_discord_response
    Discordrb::API::Channel.delete_message(App.discord_token, response_channel_rid, response_ts)
  end

  def require_topic?
    from_profile&.team&.require_topic?
  end
end
