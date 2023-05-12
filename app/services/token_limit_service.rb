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
      :#{App.error_emoji}: Sorry #{profile.link}, your token balance of #{formatted_balance} is not sufficient. The next dispersal of #{profile.team.token_quantity} tokens will occur in #{phrase}.
    TEXT
  end

  def formatted_balance
    points_format(profile.token_balance)
  end
end
