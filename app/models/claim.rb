class Claim < ApplicationRecord
  self.implicit_order_column = :created_at

  belongs_to :reward
  belongs_to :profile

  validates :price, numericality: { greater_than: 0 }

  scope :fulfilled, -> { where.not(fulfilled_at: nil) }
  scope :pending, -> { where(fulfilled_at: nil) }
  scope :search, lambda { |term|
    where('lower(claims.fulfillment_key) LIKE lower(?)', "%#{sanitize_sql_like(term)}%")
  }

  after_create_commit :after_create
  after_destroy_commit :after_destroy

  def fulfilled?
    fulfilled_at.present?
  end

  def pending?
    fulfilled_at.blank?
  end

  private

  # rubocop:disable Rails/SkipsModelValidations
  def after_create
    profile.with_lock { profile.increment!(:points_claimed, price) }
  end

  def after_destroy
    profile.with_lock { profile.decrement!(:points_claimed, price) }
  end
  # rubocop:enable Rails/SkipsModelValidations
end
