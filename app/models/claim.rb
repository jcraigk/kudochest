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

  def fulfilled?
    fulfilled_at.present?
  end

  def pending?
    fulfilled_at.blank?
  end

  # From console:
  # Zeitwerk::Loader.eager_load_all
  # Rails.application.load_tasks
  # Rake::Task['db:generate_trigger_migration'].invoke
  trigger.after(:insert) do
    <<~SQL.squish
      PERFORM pg_advisory_xact_lock(1, CAST(NEW.profile_id AS int));
      UPDATE profiles
        SET karma_claimed = karma_claimed + NEW.price
        WHERE id = NEW.profile_id;
      PERFORM pg_advisory_unlock_all();
    SQL
  end

  trigger.after(:delete) do
    <<~SQL.squish
      PERFORM pg_advisory_xact_lock(1, CAST(OLD.profile_id AS int));
      UPDATE profiles
        SET karma_claimed = karma_claimed - OLD.price
        WHERE id = OLD.profile_id;
      PERFORM pg_advisory_unlock_all();
    SQL
  end
end
