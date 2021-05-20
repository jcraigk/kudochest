# frozen_string_literal: true
class Commands::Unmute < Commands::Base
  def call
    profile.update(allow_unprompted_dm: true)
    respond_privately(I18n.t('profiles.unmuted'))
  end
end
