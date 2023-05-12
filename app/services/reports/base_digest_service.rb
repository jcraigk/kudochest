class Reports::BaseDigestService < Base::Service
  COUNT = 5
  NUM_DAYS = 7

  option :count, default: -> { COUNT }
  option :num_days, default: -> { NUM_DAYS }

  private

  def top_recipients
    top_players(recipient_quantities)
  end

  def top_givers
    top_players(giver_quantities)
  end

  def top_players(data)
    data.reject { |d| d.profile.bot_user? || !d.quantity.positive? }
        .sort_by(&:quantity)
        .reverse
        .take(count)
  end
end
