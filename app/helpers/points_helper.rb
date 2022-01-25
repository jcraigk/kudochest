# frozen_string_literal: true
module PointsHelper
  def points_format(points, opts = {})
    str =
      if opts[:label]
        num, term = points_fragments(points)
        "#{num} #{term}"
      else
        formatted_points(points)
      end
    str = "+#{str}" if opts[:plus_prefix] && points.positive?
    str = tag.span(str, class: points_class(points)) if opts[:colorize]
    str
  end

  def points_class(points)
    "points-#{points.positive? ? 'positive' : 'negative'}"
  end

  def points_fragments(points)
    if points.to_i == 1
      [App.point_singular_prefix, App.point_term]
    elsif points.to_i == -1
      [App.jab_singular_prefix, App.jab_term]
    elsif points.negative?
      [formatted_points(points.abs), App.jabs_term]
    else
      [formatted_points(points), App.points_term]
    end
  end

  def formatted_points(points)
    return '0' if points.to_f.zero?
    format('%<points>.2f', points:)
      .delete_suffix('0')
      .delete_suffix('0')
      .delete_suffix('.')
      .reverse
      .scan(/((?:\d*\.\d{1,3}|\d{1,3})-?)/)
      .join(',')
      .reverse
      .delete_prefix('0')
  end
end
