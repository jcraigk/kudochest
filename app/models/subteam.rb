# frozen_string_literal: true
class Subteam < ApplicationRecord
  belongs_to :team
  has_many :subteam_memberships # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :profiles, through: :subteam_memberships, dependent: :destroy

  validates :rid, presence: true, uniqueness: { scope: :team_id }
  validates :name, presence: true, uniqueness: { scope: :team_id }
  validates :handle, uniqueness: { scope: :team_id, allow_nil: true }

  scope :matching, lambda { |str|
    where('subteams.name ILIKE :str OR subteams.handle ILIKE :str', str: "%#{str}%")
  }

  def self.find_with_team(team_rid, subteam_rid)
    joins(:team)
      .where('teams.rid' => team_rid)
      .find_by(rid: subteam_rid)
  end
end
