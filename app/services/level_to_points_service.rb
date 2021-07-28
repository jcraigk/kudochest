# frozen_string_literal: true
class LevelToPointsService < Base::Service
  option :team
  option :level

  def call
    level_to_points
  end

  private

  def level_to_points
    level == 1 ? 0 : compute_points
  end

  def compute_points
    (send("#{level_curve}_progress") * max_level_points).ceil
  end

  def linear_progress
    (level - 1) / (max_level - 1).to_f
  end

  def gentle_progress
    linear_progress**App.gentle_level_coefficient
  end

  def steep_progress
    linear_progress**App.steep_level_coefficient
  end

  def max_level
    @max_level ||= team.max_level
  end

  def max_level_points
    @max_level_points ||= team.max_level_points
  end

  def level_curve
    @level_curve ||= team.level_curve
  end
end
