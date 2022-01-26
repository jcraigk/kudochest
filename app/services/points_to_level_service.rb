# frozen_string_literal: true
class PointsToLevelService < Base::Service
  option :team
  option :points

  def call
    points_to_level
  end

  private

  def points_to_level
    points.positive? ? [compute_level, team.max_level].min : 1
  end

  def compute_level
    (send("#{level_curve}_progress") * (max_level - 1)).to_f.floor + 1
  end

  def linear_progress
    points / max_level_points.to_f
  end

  def gentle_progress
    linear_progress**(1 / App.gentle_level_coefficient)
  end

  def steep_progress
    linear_progress**(1 / App.steep_level_coefficient)
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
