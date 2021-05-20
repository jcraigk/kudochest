# frozen_string_literal: true
class RewardClaimService < Base::Service
  option :reward
  option :profile

  attr_reader :error

  def call
    OpenStruct.new(claim: create_claim, error: error)
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
    @error = t('shop.insufficient_karma', reward: reward.name) unless sufficient_karma?
    @error = t('shop.insufficient_quantity') unless reward.remaining.positive?
    @error.blank?
  end

  def sufficient_karma?
    profile.karma_unclaimed >= reward.price
  end

  def claim_attrs
    base_attrs.merge(fulfillment_attrs).compact
  end

  def base_attrs
    {
      profile: profile,
      reward: reward,
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
end
