module EntityReferenceHelper
  def helpers
    ActionController::Base.helpers
  end

  def channel_link(rid)
    "<#{CHAN_PREFIX}#{rid}>"
  end

  def channel_webref(name)
    helpers.tag.span("#{CHAN_PREFIX}#{name}", class: 'chat-ref')
  end

  def subteam_webref(name)
    helpers.tag.span(name, class: 'chat-ref')
  end
end
