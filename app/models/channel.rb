class Channel < ApplicationRecord
  include ChannelDecorator

  belongs_to :team

  attribute :shared, :boolean, default: false
  attribute :private, :boolean, default: false

  validates :rid, uniqueness: { scope: :team_id }
  validates :name, presence: true, uniqueness: { scope: :team_id }

  scope :matching, ->(str) { where('channels.name ILIKE ?', "%#{str}%") }

  def self.find_with_team(team_rid, channel_rid)
    joins(:team)
      .where('teams.rid' => team_rid)
      .find_by(rid: channel_rid)
  end
end
