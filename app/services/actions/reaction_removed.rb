# frozen_string_literal: true
class Actions::ReactionRemoved < Actions::ReactionBase
  def call
    return unless process_emoji?

    destroy_tips
    respond
  end

  private

  def respond
    ChatResponse.new(mode: :silent)
  end

  def destroy_tips
    Tip.undoable.where(event_ts: event_ts).destroy_all
  end
end
