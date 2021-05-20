# frozen_string_literal: true
class Commands::Mute < Commands::Base
  def call
    profile.update(allow_unprompted_dm: false)
    respond_privately(I18n.t('profiles.muted'))
  end
end
