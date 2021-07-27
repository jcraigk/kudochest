# frozen_string_literal: true
class BonusesController < ApplicationController
  before_action :ensure_manager!
  before_action :fetch_current_team

  def index; end

  def create
    BonusCalculatorWorker.perform_async(worker_args.to_json)
    redirect_to bonuses_path, notice: t('bonuses.calculation_requested', email: current_user.email)
  end

  private

  def worker_args
    {
      team_id: current_team.id,
      start_date: params[:start_date],
      end_date: params[:end_date],
      include_streak_points: params[:include_streak_points],
      include_imported_points: params[:include_imported_points],
      style: params[:style],
      pot_size: params[:pot_size],
      dollar_per_point: params[:dollar_per_point]
    }
  end

  def ensure_manager!
    redirect_to dashboard_path unless current_user.owned_teams.any?
  end
end
