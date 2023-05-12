class Commands::Undo < Commands::Base
  attr_reader :text

  def call
    return respond_failure(I18n.t('tips.nothing_to_undo')) if tips.none?

    destroy_tips
    respond
  end

  private

  def respond
    ChatResponse.new \
      mode: :private,
      text: "You revoked #{points_clause}"
  end

  def destroy_tips
    TipOutcomeService.call(tips:, destroy: true)
  end

  def tips
    @tips ||= Tip.where(event_ts: undoable_event_ts)
  end

  def undoable_event_ts
    Tip.undoable
       .where(from_profile: profile)
       .order(created_at: :desc)
       .pick(:event_ts)
  end

  def points_clause
    noticible_tips_by_quantity.map do |quantity, quant_tips|
      str = "#{points_format(quantity, label: true)} from #{frag_sentence(quant_tips)}"
      str += ' each' if quant_tips.size.between?(2, App.max_response_mentions)
      str
    end.to_sentence
  end

  def frag_sentence(tips)
    return "#{tips.size} users" if tips.size > App.max_response_mentions
    tips.map { |t| t.to_profile.link }.to_sentence
  end

  def noticible_tips_by_quantity
    tips.reject { |t| t.source == 'streak' }.group_by(&:quantity).sort.reverse
  end
end
