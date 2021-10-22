# frozen_string_literal: true
class Team < ApplicationRecord
  extend Enumerize
  include Incrementable
  include Sluggi::Slugged
  include TeamDecorator

  CACHED_ATTRS = %w[
    active api_key app_profile_rid app_subteam_rid avatar_url enable_cheers
    enable_fast_ack tip_emoji ditto_emoji enable_emoji emoji_quantity tip_increment
    log_channel_rid hint_channel_rid max_points_per_tip platform response_mode
    response_theme show_channel show_note time_zone tip_notes enable_topics
    require_topic
  ].freeze
  TIP_INCREMENTS = [1.0, 0.5, 0.25, 0.1, 0.05, 0.01].freeze
  EMOJI_VALS = [1.0, 2.0, 3.0, 4.0, 5.0, 0.75, 0.5, 0.25, 0.2, 0.1, 0.05, 0.02, 0.01].freeze
  WEEKDAYS = Date::DAYNAMES.map(&:downcase).freeze

  has_many :channels, dependent: :destroy
  has_many :profiles, dependent: :destroy
  has_many :subteams, dependent: :destroy
  has_many :topics, dependent: :destroy
  has_many :rewards, dependent: :destroy
  belongs_to :owning_user, class_name: 'User', foreign_key: :owner_user_id, inverse_of: :owned_teams

  enumerize :platform,
            in: %w[slack discord]
  enumerize :level_curve,
            in: %w[gentle steep linear],
            default: 'gentle'
  enumerize :response_mode,
            in: %w[adaptive convo reply direct silent],
            default: 'adaptive'
  enumerize :response_theme,
            in: %w[basic fancy quiet quiet_stat gif_day gif_night],
            default: 'basic'
  enumerize :tip_notes,
            in: %w[optional required disabled],
            default: 'optional'
  enumerize :token_frequency,
            in: %w[daily weekly monthly quarterly yearly],
            default: 'weekly'
  enumerize :week_start_day,
            in: Date::DAYNAMES.map(&:downcase),
            default: 'monday'
  enumerize :hint_frequency,
            in: %w[never hourly daily weekly],
            default: 'never'

  attribute :active,             :boolean, default: true
  attribute :enable_cheers,      :boolean, default: true
  attribute :enable_emoji,       :boolean, default: true
  attribute :enable_fast_ack,    :boolean, default: true
  attribute :enable_levels,      :boolean, default: true
  attribute :enable_loot,        :boolean, default: true
  attribute :enable_streaks,     :boolean, default: true
  attribute :enable_topics,      :boolean, default: false
  attribute :installed,          :boolean, default: true
  attribute :throttle_tips,      :boolean, default: false
  attribute :notify_tokens,      :boolean, default: true
  attribute :require_topic,      :boolean, default: false
  attribute :show_channel,       :boolean, default: true
  attribute :show_note,          :boolean, default: true
  attribute :split_tip,          :boolean, default: false
  attribute :weekly_report,      :boolean, default: true
  attribute :tip_emoji,          :string,  default: App.default_tip_emoji
  attribute :ditto_emoji,        :string,  default: App.default_ditto_emoji
  attribute :time_zone,          :string,  default: App.default_time_zone
  attribute :streak_duration,    :integer, default: App.default_streak_duration
  attribute :streak_reward,      :integer, default: App.default_streak_reward
  attribute :max_level,          :integer, default: App.default_max_level
  attribute :max_level_points,   :integer, default: App.default_max_level_points
  attribute :token_quantity,     :integer, default: App.default_token_quantity
  attribute :token_max,          :integer, default: App.default_token_max
  attribute :action_hour,        :integer, default: App.default_action_hour
  attribute :work_days_mask,     :integer, default: 62 # monday - friday
  attribute :member_count,       :integer, default: 0
  attribute :points_sent,        :decimal, default: 0.0
  attribute :max_points_per_tip, :integer, default: 5
  attribute :emoji_quantity,     :decimal, default: 1
  attribute :tip_increment,      :decimal, default: 1

  validates :platform, presence: true
  validates :api_key, uniqueness: true
  validates :tip_increment, inclusion: { in: TIP_INCREMENTS }
  validates :emoji_quantity, inclusion: { in: EMOJI_VALS }
  validates :name, presence: true
  validates :rid, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :avatar_url, presence: true
  validates :action_hour, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 23
  }
  validates :token_quantity, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: App.max_token_quantity
  }
  validates :token_max, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: App.max_token_max
  }
  validates :max_level, numericality: {
    greater_than_or_equal_to: 10,
    less_than_or_equal_to: 99
  }
  validates :max_level_points, numericality: {
    greater_than_or_equal_to: 100,
    less_than_or_equal_to: 10_000
  }
  validates :max_points_per_tip, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: App.max_points_per_tip
  }
  validates :streak_duration, numericality: {
    greater_than_or_equal_to: App.min_streak_duration,
    less_than_or_equal_to: App.max_streak_duration
  }
  validates :streak_reward, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: App.max_streak_reward
  }
  validates_with EmojiQuantityValidator
  validates_with RequireTopicValidator
  validates_with TokenQuantityWithinTokenMaxValidator
  validates_with WeekStartDayInWorkDaysValidator
  validates_with WorkDaysValidator

  before_update :bust_cache, if: -> { (changes.keys & CACHED_ATTRS).any? }
  before_update :sync_topic_attrs
  after_update_commit :reset_profile_tokens, if: :saved_change_to_throttle_tips?
  after_update_commit :sync_remote, if: :saved_change_to_active?
  after_update_commit :join_log_channel, if: :saved_change_to_log_channel_rid?

  scope :active, -> { where(active: true) }

  def self.bust_cache
    find_each do |team|
      Cache::TeamConfig.new(team.rid).delete
    end
  end

  def work_days=(weekdays)
    self.work_days_mask = (weekdays & WEEKDAYS).sum { |d| 2**WEEKDAYS.index(d) }
  end

  def work_days
    WEEKDAYS.reject do |d|
      ((work_days_mask.to_i || 0) & (2**WEEKDAYS.index(d))).zero?
    end
  end

  def next_tokens_at
    NextIntervalService.call(
      team: self,
      attr: :token_frequency,
      start_at: tokens_disbursed_at
    )
  end

  def next_hint_at
    NextIntervalService.call(
      team: self,
      attr: :hint_frequency,
      start_at: hint_posted_at
    )
  end

  def app_profile
    @app_profile ||= profiles.find_by(rid: app_profile_rid)
  end

  def sync_remote(first_run: false)
    return unless active?
    ChannelWorker.perform_async(rid)
    ProfileWorker.perform_async(rid, first_run)
    EmojiInstallWorker.perform_async(rid) if first_run && platform.discord?
  end

  def bust_cache
    Cache::TeamConfig.new(rid).delete
  end

  private

  def reset_profile_tokens
    TokenResetWorker.perform_async(id)
  end

  def slug_candidates
    [name, "#{name}-#{SecureRandom.hex(3)}"]
  end

  def slug_value_changed?
    name_changed?
  end

  def join_log_channel
    return unless platform.slack? && log_channel_rid.present?
    Slack::ChannelJoinService.call(team: self, channel_rid: log_channel_rid)
  end

  def sync_topic_attrs
    self.require_topic = false unless enable_topics?
  end
end
