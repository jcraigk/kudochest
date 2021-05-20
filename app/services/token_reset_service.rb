# frozen_string_literal: true
class TokenResetService < Base::Service
  option :team

  def call
    team.profiles.find_each do |profile|
      profile.update(tokens_accrued: profile.karma_sent)
    end

    TokenDispersalService.call(team: team, notify: false) if team.limit_karma?
  end
end
