# frozen_string_literal: true
class Profile < ApplicationRecord
  include ProfileDecorator
  include Sluggi::Slugged
  include TokenRegisterable

  belongs_to :team
  belongs_to :user, optional: true
  has_many :tips_received,
           class_name: 'Tip',
           foreign_key: :to_profile_id,
           inverse_of: :to_profile,
           dependent: :destroy
  has_many :tips_sent,
           class_name: 'Tip',
           foreign_key: :from_profile_id,
           inverse_of: :from_profile,
           dependent: :destroy
  has_many :subteam_memberships # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :subteams, through: :subteam_memberships, dependent: :destroy
  has_many :claims, dependent: :destroy

  attribute :allow_dm,            :boolean, default: true
  attribute :bot_user,            :boolean, default: false
  attribute :deleted,             :boolean, default: false
  attribute :weekly_report,       :boolean, default: true
  attribute :infinite_tokens,     :boolean, default: false
  attribute :points_claimed,      :integer, default: 0
  attribute :points_received,     :decimal, default: 0.0
  attribute :points_sent,         :decimal, default: 0.0
  attribute :jabs_received,       :decimal, default: 0.0
  attribute :jabs_sent,           :decimal, default: 0.0
  attribute :balance,             :decimal, default: 0.0
  attribute :streak_count,        :integer, default: 0
  attribute :tokens_accrued,      :integer, default: 0
  attribute :tokens_forfeited,    :decimal, default: 0.0

  alias_attribute :points, :points_received

  validates :rid, uniqueness: { scope: :team_id }
  validates :avatar_url, presence: true
  validates :display_name, presence: true
  validates :slug, presence: true
  validates_with OneProfilePerTeamPerUserValidator

  default_scope { includes(:team) }
  scope :active, -> { where(bot_user: false, deleted: false) }
  scope :matching, lambda { |str|
    where('profiles.display_name ILIKE :str OR profiles.real_name ILIKE :str', str: "%#{str}%")
  }

  def active?
    !bot_user && !deleted
  end

  def reset_slug!
    update!(slug: clean_slug(slug_value))
  end

  def self.collection_with_team(team_rid, profile_rids)
    where(rid: profile_rids)
      .joins(:team)
      .where('teams.rid' => team_rid)
      .distinct
  end

  def self.find_with_team(team_rid, profile_rid)
    joins(:team)
      .where('teams.rid' => team_rid)
      .find_by(rid: profile_rid)
  end

  def token_balance
    tokens_accrued - points_sent
  end

  private

  def slug_candidates
    [base_slug, "#{base_slug}-#{SecureRandom.hex(3)}"]
  end

  def slug_value_changed?
    display_name_changed?
  end

  def base_slug
    "#{team&.slug}-#{display_name}"
  end
end
