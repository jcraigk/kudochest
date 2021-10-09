# frozen_string_literal: true
class Reports::BaseDigestService < Base::Service
  COUNT = 10
  NUM_DAYS = 7

  option :count, default: -> { COUNT }
  option :num_days, default: -> { NUM_DAYS }

  private

  def top_recipients
    recipient_quantities.reject { |data| data.quantity.zero? }
                        .sort_by(&:quantity)
                        .reverse
                        .take(count)
  end

  def top_benefactors
    benefactor_quantities.reject { |data| data.quantity.zero? }
                         .sort_by(&:quantity)
                         .reverse
                         .take(count)
  end
end
