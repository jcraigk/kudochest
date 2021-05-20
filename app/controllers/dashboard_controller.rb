# frozen_string_literal: true
class DashboardController < ApplicationController
  def show
    return unless current_profile
    # TODO: This is a hack to fix kaminari anchor bug
    if params[:paged].present?
      return redirect_to dashboard_path(page: params[:page], anchor: :recent)
    end
    build_dashboard_for(current_profile)
  end
end
