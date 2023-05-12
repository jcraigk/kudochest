class Actions::ReactionRemoved < Actions::ReactionBase
  def call
    return unless process_emoji?

    destroy_tips
    respond
  end

  private

  def destroy_tips
    TipOutcomeService.call(tips:, destroy: true)
  end

  def respond
    ChatResponse.new(mode: :silent)
  end

  def tips
    @tips ||= Tip.undoable.where(event_ts:)
  end
end
