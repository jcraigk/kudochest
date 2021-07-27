# frozen_string_literal: true
module PointsHelper
  def points_format(points, opts = {})
    str = formatted_points(points)
    return str unless opts[:label] == true

    one = points.to_i == 1
    str = App.one_replacement if one && App.one_replacement.present?
    label = (one ? App.point_term : App.points_term)
    "#{str} #{label}".squish
  end

  def formatted_points(points)
    return '0' if points.to_f.zero?
    format('%<points>.2f', points: points)
      .delete_suffix('0')
      .delete_suffix('0')
      .delete_suffix('.')
      .reverse
      .scan(/(\d*\.\d{1,3}|\d{1,3})/)
      .join(',')
      .reverse
      .delete_prefix('0')
  end
end
