# frozen_string_literal: true
class Commands::Base < Base::Service
  include PointsHelper

  option :team_rid
  option :profile_rid
  option :text, default: proc { '' }

  def call
    'Override in child class'
  end

  protected

  def team
    @team ||= profile.team
  end

  def profile
    @profile ||= Profile.find_with_team(team_rid, profile_rid)
  end

  def respond_privately(text)
    ChatResponse.new(mode: :private, text: text)
  end

  def respond_failure(text)
    ChatResponse.new(mode: :error, text: ":#{App.error_emoji}: #{text}")
  end

  def response_text
    team.platform.discord? ? discord_response_text : base_text
  end

  def discord_response_text
    base_text.gsub('*', '**')
  end
end
