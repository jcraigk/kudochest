class Actions::Base < Base::Service
  param :params

  def call
    'Override in child class'
  end

  protected

  def profile
    @profile ||= Profile.find_with_team(params[:team_rid], params[:profile_rid])
  end

  def team
    @team ||= profile&.team
  end
end
