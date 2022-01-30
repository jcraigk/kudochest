# frozen_string_literal: true
class PublicController < ApplicationController
  skip_before_action :require_login
  before_action :set_default_platform

  layout 'public'

  def landing
    redirect_to(current_user ? dashboard_path : login_path)
  end

  private

  def set_default_platform
    session[:platform] ||= :slack
    session[:platform] = params[:platform].to_sym if params[:platform]
    @platform = session[:platform]
  end
end
