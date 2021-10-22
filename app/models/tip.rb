# frozen_string_literal: true
class Tip < ApplicationRecord
  extend Enumerize
  include TipDecorator

  UNDOABLE_SOURCES = %w[modal plusplus reaction ditto reply streak].freeze

  enumerize :source, in: %w[auto modal plusplus reaction ditto reply streak import]

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

  after_create_commit :after_create
  after_destroy_commit :after_destroy
  after_commit :refresh_leaderboards

  scope :undoable, lambda {
    where(source: UNDOABLE_SOURCES)
      .where('created_at > ?', Time.current - App.undo_cutoff)
      .order(created_at: :desc)
  }
  scope :search_notes, lambda { |term|
    where('lower(tips.note) LIKE lower(?)', "%#{sanitize_sql_like(term)}%")
  }

  def topic_name
    topic&.name || 'None'
  end

  private

  def after_create
    transaction do
      update_timestamps
      update_points
    end
  end

  def update_timestamps
    from_profile.update!(last_tip_sent_at: created_at)
    to_profile.update!(last_tip_received_at: created_at)
    to_profile.team.update!(last_tip_sent_at: created_at)
  end

  def after_destroy
    transaction do
      reset_timestamps
      update_points(decrement: true)
      delete_chat_response
    end
  end

  def reset_timestamps
    from_profile.update!(last_tip_sent_at: last_sent_tip&.created_at)
    to_profile.update!(last_tip_received_at: last_received_tip&.created_at)
  end

  def refresh_leaderboards
    LeaderboardRefreshWorker.perform_async(to_profile.team.id)
    LeaderboardRefreshWorker.perform_async(to_profile.team.id, true)
  end

  def last_sent_tip
    Tip.where(from_profile_id: from_profile_id).order(created_at: :desc).first
  end

  def last_received_tip
    Tip.where(to_profile_id: to_profile_id).order(created_at: :desc).first
  end

  def update_points(decrement: false)
    from_profile.increment_with_sql!(:points_sent, quantity, decrement)
    to_profile.increment_with_sql!(:points_received, quantity, decrement)
    to_profile.team.increment_with_sql!(:points_sent, quantity, decrement)
  end

  def delete_chat_response
    return if response_channel_rid.blank? || response_ts.blank?
    send("delete_#{from_profile.team.platform}_response")
  end

  def delete_slack_response
    from_profile.team.slack_client.chat_delete(channel: response_channel_rid, ts: response_ts)
  rescue Slack::Web::Api::Errors::MessageNotFound
    nil
  end

  def delete_discord_response
    Discordrb::API::Channel.delete_message(App.discord_token, response_channel_rid, response_ts)
  end

  def require_topic?
    from_profile&.team&.require_topic?
  end
end
