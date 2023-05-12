module ChannelDecorator
  extend ActiveSupport::Concern
  include EntityReferenceHelper

  def link
    channel_link(rid)
  end

  def webref
    channel_webref(name)
  end
end
