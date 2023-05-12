module TipHelper
  def chat_permalink_for(tip)
    return if tip.chat_permalink.blank?
    link_to \
      fa_icon('external-link', 'btn-icon'),
      tip.chat_permalink,
      target: '_blank',
      rel: 'noopener'
  end
end
