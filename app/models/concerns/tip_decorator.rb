# frozen_string_literal: true
module TipDecorator
  extend ActiveSupport::Concern

  def helpers
    ActionController::Base.helpers
  end

  def channel_webref
    name = from_channel_name.presence || 'Private'
    helpers.tag.span("#{CHAN_PREFIX}#{name}", class: 'chat-ref')
  end
end
