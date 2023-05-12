class Commands::Preferences < Commands::Base
  def call
    return admin_command if team.platform.discord?
    ChatResponse.new(mode: :prefs_modal)
  end

  private

  def admin_command
    Commands::Admin.call(team_rid:, profile_rid:)
  end
end
