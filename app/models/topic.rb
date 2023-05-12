class Topic < ApplicationRecord
  self.implicit_order_column = :name

  belongs_to :team
  has_many :tips, dependent: :nullify

  attribute :active, :boolean, default: true

  validates :name, presence: true, uniqueness: { scope: :team_id }
  validates :emoji, uniqueness: { scope: :team_id }
  validates :keyword,
            presence: true,
            format: { with: /\A[a-z][a-z0-9_]+\z/, message: :snake_case },
            length: { within: 2..20 },
            uniqueness: { scope: :team_id }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :search, lambda { |term|
    where \
      'lower(topics.name) LIKE lower(:term) OR lower(topics.description) LIKE lower(:term) ' \
      'OR lower(topics.emoji) LIKE lower(:term) OR lower(topics.keyword) LIKE lower(:term)',
      term: "%#{sanitize_sql_like(term)}%"
  }

  after_commit :update_team

  private

  def update_team
    team.update!(require_topic: false) if team.topics.active.count.zero?
    team.bust_cache
  end
end
