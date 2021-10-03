# frozen_string_literal: true
class HintService < Base::Service
  option :team

  def call
    return if team.hint_channel_rid.blank? || team.hint_frequency.never?
    post_random_hint
  end

  private

  def post_random_hint
    responder.call(team_rid: team.rid, team_config: team.config, mode: :hint, text: text)
    team.update!(hint_posted_at: Time.current)
  end

  def text
    ":bulb: *Hint*: #{hints.sample}"
  end

  def hints
    @hints ||=
      YAML.safe_load(
        File.read(Rails.root.join('config/hints.yml'))
      )['hints']
  end

  def responder
    @responder ||= "#{team.platform.titleize}::PostService".constantize
  end
end
