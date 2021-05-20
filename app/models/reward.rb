# frozen_string_literal: true
class Reward < ApplicationRecord
  self.implicit_order_column = :created_at

  belongs_to :team
  has_many :claims, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :team_id }
  validates :price, numericality: { greater_than: 0 }
  validates_with QuantityCoversClaimCountValidator
  validates_with AutoFulfillRequiresKeysValidator

  attribute :active,            default: false
  attribute :auto_fulfill,      default: false
  attribute :quantity,          default: 0

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :search, lambda { |term|
    where(
      'lower(rewards.name) LIKE lower(:term) OR lower(rewards.description) LIKE lower(:term) ' \
      'OR lower(rewards.fulfillment_keys) LIKE lower(:term)',
      term: "%#{sanitize_sql_like(term)}%"
    )
  }

  def self.shop_list(team)
    Reward.active
          .where(team: team)
          .order(price: :asc, name: :asc)
          .select { |reward| reward.remaining.positive? }
  end

  def remaining
    return quantity - claims.count unless auto_fulfill?
    fulfillment_keys&.split("\n")&.count(&:present?) || 0
  end
end
