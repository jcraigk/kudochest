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

  after_create_commit :update_point_totals
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

  def update_point_totals(subtract: false)
    plus_or_minus, timestamp = subtract ? ['-', nil] : ['+', created_at]
    transaction do
      update_from_profile_points(plus_or_minus, timestamp)
      update_to_profile_points(plus_or_minus, timestamp)
      update_team_points(plus_or_minus)
    end
  end

  def update_from_profile_points(plus_or_minus, timestamp)
    from_profile.with_lock do
      points_sent = from_profile.points_sent.send(plus_or_minus, quantity)
      last_tip_sent_at = timestamp || last_sent_tip&.created_at
      from_profile.update!(points_sent:, last_tip_sent_at:)
    end
  end

  def update_to_profile_points(plus_or_minus, timestamp)
    to_profile.with_lock do
      points_received = to_profile.points_received.send(plus_or_minus, quantity)
      last_tip_received_at = timestamp || last_received_tip&.created_at
      to_profile.update!(points_received:, last_tip_received_at:)
    end
  end

  def update_team_points(plus_or_minus)
    team.with_lock do
      points_sent = team.points_sent.send(plus_or_minus, quantity)
      team.update!(points_sent:)
    end
  end

  def after_destroy
    update_point_totals(subtract: true)
    delete_chat_response
  end

  def refresh_leaderboards
    LeaderboardRefreshWorker.perform_async(team.id)
    LeaderboardRefreshWorker.perform_async(team.id, true)
  end

  def team
    @team ||= from_profile.team
  end

  def last_sent_tip
    Tip.where(from_profile_id:).order(created_at: :desc).first
  end

  def last_received_tip
    Tip.where(to_profile_id:).order(created_at: :desc).first
  end

  def delete_chat_response
    return if response_channel_rid.blank? || response_ts.blank?
    send("delete_#{team.platform}_response")
  end

  def delete_slack_response
    team.slack_client.chat_delete(channel: response_channel_rid, ts: response_ts)
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
