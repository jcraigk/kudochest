# frozen_string_literal: true
class BonusCalculatorWorker
  include Sidekiq::Worker

  def perform(json_params) # rubocop:disable Metrics/AbcSize
    params = JSON[json_params].symbolize_keys
    params[:include_streak_points] = params[:include_streak_points] == '1'
    params[:include_imported_points] = params[:include_imported_points] == '1'
    params[:pot_size] = params[:pot_size].presence&.to_f || 0
    params[:dollar_per_point] = params[:dollar_per_point].presence&.to_f || 0
    params[:team] = Team.find(params[:team_id])

    BonusCalculatorService.call(params)
  end
end
