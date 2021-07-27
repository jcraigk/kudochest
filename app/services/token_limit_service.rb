# frozen_string_literal: true
class TokenLimitService < Base::Service
  option :profile
  option :quantity

  def call
    return error_text if need_tokens?
    false
  end

  private

  def need_tokens?
    !profile.infinite_tokens && profile.team.throttle_tips? && profile.token_balance < quantity
  end

  def error_text
    phrase = distance_of_time_in_words(Time.current, profile.team.next_tokens_at)
    <<~TEXT.chomp
      :#{App.error_emoji}: Giving #{formatted_quantity} karma would exceed your token balance of #{formatted_balance}. The next dispersal of #{profile.team.token_quantity} tokens will occur in #{phrase}.
    TEXT
  end

  def formatted_quantity
    points_format(quantity)
  end

  def formatted_balance
    points_format(profile.token_balance)
  end
end
