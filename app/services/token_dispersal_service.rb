# frozen_string_literal: true
class TokenDispersalService < Base::Service
  option :team
  option :notify, default: proc { true }

  def call
    Team.transaction { disburse_tokens }
  end

  private

  def disburse_tokens
    team.profiles.active.where(infinite_tokens: false).find_each do |profile|
      apply_tokens(profile)
      notify_user(profile)
    end

    team.update!(tokens_disbursed_at: Time.current)
  end

  def notify_user(profile)
    return unless notify && team.notify_tokens_disbursed && profile.allow_unprompted_dm?
    send_direct_message(profile)
  end

  def next_dispersal_text
    phrase = distance_of_time_in_words(Time.current, team.next_tokens_at)
    <<~TEXT.chomp
      The next dispersal of #{number_with_delimiter(team.token_quantity)} tokens will occur in #{phrase}.
    TEXT
  end

  def success_text(profile)
    <<~TEXT.chomp
      You received #{number_with_delimiter(quantity)} tokens#{discord_guild}, bringing your total to #{points_format(profile.token_balance)}.
    TEXT
  end

  def forfeit_text
    <<~TEXT.chomp
      We tried to give you #{number_with_delimiter(quantity)} tokens#{discord_guild}, but you maxed out at #{number_with_delimiter(max)}.
    TEXT
  end

  def discord_guild
    return unless team.platform.discord?
    " for the #{team.name} guild"
  end

  def send_direct_message(profile)
    "#{team.plat}::PostService".constantize.call(
      team_config: team.config,
      team_rid: team.rid,
      profile_rid: profile.rid,
      mode: :direct,
      text: message_content(profile)
    )
  end

  def message_content(profile)
    base_text = profile.tokens_forfeited.positive? ? forfeit_text : success_text(profile)
    [base_text, next_dispersal_text].join(' ')
  end

  def apply_tokens(profile)
    accrued = [(max - profile.token_balance), quantity].min
    profile.tokens_accrued += accrued
    profile.tokens_forfeited += quantity - accrued
    profile.save!
  end

  def max
    @max ||= team.token_max
  end

  def quantity
    @quantity ||= team.token_quantity
  end
end
