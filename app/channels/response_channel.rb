class ResponseChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_profile_team
  end
end
