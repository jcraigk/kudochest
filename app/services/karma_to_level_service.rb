# frozen_string_literal: true
class KarmaToLevelService < Base::Service
  option :team
  option :karma

  def call
    karma_to_level
  end

  private

  def karma_to_level
    karma.zero? ? 1 : [compute_level, team.max_level].min
  end

  def compute_level
    (send("#{level_curve}_progress") * (max_level - 1)).to_f.floor + 1
  end

  def linear_progress
    karma / max_level_karma.to_f
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

  def max_level_karma
    @max_level_karma ||= team.max_level_karma
  end

  def level_curve
    @level_curve ||= team.level_curve
  end
end
