class TokenResetService < Base::Service
  option :team

  def call
    team.profiles.find_each do |profile|
      profile.update(tokens_accrued: profile.points_sent)
    end

    TokenDispersalService.call(team:, notify: false) if team.throttle_tips?
  end
end
