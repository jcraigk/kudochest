# frozen_string_literal: true
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

  def after_create
    profile.increment_with_sql!(:points_claimed, price, false)
  end

  def after_destroy
    profile.increment_with_sql!(:points_claimed, price, true)
  end
end
