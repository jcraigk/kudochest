class RewardClaimService < Base::Service
  option :reward
  option :profile

  attr_reader :error

  def call
    ClaimResponse.new(create_claim, error)
  end

  private

  def create_claim
    return false unless valid_claim?
    Reward.transaction do
      reward.update!(fulfillment_keys: remaining_keys) if reward.auto_fulfill?
      Claim.create!(claim_attrs)
    end
  end

  def valid_claim?
    @error = insufficient_points_msg unless sufficient_points?
    @error = t('shop.insufficient_quantity') unless reward.remaining.positive?
    @error.blank?
  end

  def insufficient_points_msg
    t('shop.insufficient_points', reward: reward.name, points: App.points_term)
  end

  def sufficient_points?
    profile.points_unclaimed >= reward.price
  end

  def claim_attrs
    base_attrs.merge(fulfillment_attrs).compact
  end

  def base_attrs
    {
      profile:,
      reward:,
      price: reward.price
    }
  end

  def fulfillment_attrs
    return {} unless reward.auto_fulfill?
    {
      fulfilled_at: Time.current,
      fulfillment_key: fulfillment_keys.first
    }
  end

  def fulfillment_keys
    @fulfillment_keys ||= reward.fulfillment_keys&.split("\n")&.reject(&:blank?) || []
  end

  def remaining_keys
    @remaining_keys ||= fulfillment_keys[1..]&.join("\n")
  end

  ClaimResponse = Struct.new(:claim, :error)
end
