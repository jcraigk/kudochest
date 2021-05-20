# frozen_string_literal: true
class Commands::Shop < Commands::Base
  def call
    return respond_disabled unless team.enable_loot?
    respond_success
  end

  private

  def respond_disabled
    OpenStruct.new(mode: :private, text: t('shop.disabled'))
  end

  def respond_success
    OpenStruct.new(mode: :private, text: response_text)
  end

  def base_text
    return t('shop.empty') if rewards.blank?
    [header, shop_rows, balance_sentence].flatten.join("\n")
  end

  def header
    [t('shop.command_title')]
  end

  def balance_sentence
    t(
      'shop.karma_balance_chat',
      claimed: karma_format(profile.karma_claimed),
      accrued: karma_format(profile.karma),
      remaining: karma_format(profile.karma_unclaimed)
    )
  end

  def shop_rows
    rewards.map do |reward|
      t(
        'shop.reward_for_price_chat',
        reward: reward.name,
        quantity: number_with_delimiter(reward.price)
      )
    end
  end

  def rewards
    @rewards = Reward.shop_list(team)
  end
end
