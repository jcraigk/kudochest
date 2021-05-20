# frozen_string_literal: true
class BonusCalculatorWorker
  include Sidekiq::Worker

  def perform(json_params) # rubocop:disable Metrics/AbcSize
    params = JSON[json_params].symbolize_keys
    params[:include_streak_karma] = params[:include_streak_karma] == '1'
    params[:include_imported_karma] = params[:include_imported_karma] == '1'
    params[:pot_size] = params[:pot_size].presence&.to_f || 0
    params[:karma_point_value] = params[:karma_point_value].presence&.to_f || 0
    params[:team] = Team.find(params[:team_id])

    BonusCalculatorService.call(params)
  end
end
