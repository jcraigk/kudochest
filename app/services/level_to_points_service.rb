# frozen_string_literal: true
class LevelToPointsService < Base::Service
  option :team
  option :level

  def call
    level_to_karma
  end

  private

  def level_to_karma
    level == 1 ? 0 : compute_karma
  end

  def compute_karma
    (send("#{level_curve}_progress") * max_level_karma).ceil
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

  def max_level_karma
    @max_level_karma ||= team.max_level_karma
  end

  def level_curve
    @level_curve ||= team.level_curve
  end
end
