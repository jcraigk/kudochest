# frozen_string_literal: true
class Commands::Claim < Commands::Base
  attr_reader :claim

  def call
    return respond_disabled unless team.enable_loot?
    return respond_error(unrecognized_reward_text) if reward.blank?
    return respond_error(result.error) if result.error.present?
    respond_success
  end

  private

  def respond_disabled
    OpenStruct.new(mode: :private, text: t('shop.disabled'))
  end

  def result
    @result ||= RewardClaimService.call(profile: profile, reward: reward)
  end

  def respond_error(text)
    OpenStruct.new(mode: :error, text: text)
  end

  def respond_success
    @claim = result.claim
    OpenStruct.new(mode: :private, text: response_text)
  end

  def unrecognized_reward_text
    ":#{App.error_emoji}: #{t('shop.unrecognized_reward')}"
  end

  def base_text
    [claimed_fragment, fulfillment_fragment].join("\n")
  end

  def claimed_fragment
    t('shop.claimed_for_karma', reward: reward.name, quantity: claim.price)
  end

  def fulfillment_fragment
    return t('shop.fulfillment_pending') unless claim.fulfillment_key?
    t('shop.fulfillment_key_with_val', value: claim.fulfillment_key)
  end

  def reward
    @reward =
      Reward.where(team: profile.team, active: true)
            .where('lower(name) = ?', text.downcase)
            .first
  end
end
