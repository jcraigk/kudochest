class Tip < ApplicationRecord
  extend Enumerize
  include TipDecorator

  enumerize :source, in: %w[
    seed modal inline point_reaction jab_reaction ditto_reaction topic_reaction reply streak import
  ]

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

  after_destroy_commit :delete_chat_response

  scope :undoable, lambda {
    where('created_at > ?', Time.current - App.undo_cutoff)
      .order(created_at: :desc)
  }
  scope :search_notes, lambda { |term|
    where('lower(tips.note) LIKE lower(?)', "%#{sanitize_sql_like(term)}%")
  }

  delegate :team, to: :from_profile

  private

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
