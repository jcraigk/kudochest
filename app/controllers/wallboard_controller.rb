class WallboardController < ApplicationController
  def show
    redirect_to dashboard_path unless current_profile
  end
end
