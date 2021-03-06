# frozen_string_literal: true
module PointsHelper
  def points_format(points, opts = {})
    return '0' if points.blank?
    points = BigDecimal(points.to_s)
    str = opts[:label] ? point_label_fragments(points, opts).join(' ') : formatted_points(points)
    str = "+#{str}" if opts[:plus_prefix] && points.positive?
    str = tag.span(str, class: points_class(points)) if opts[:colorize]
    str
  end

  def points_class(points)
    "points-#{points.positive? ? 'positive' : 'negative'}"
  end

  def point_label_fragments(points, opts)
    if points == 1 then one_point_fragments
    elsif points == -1 then minus_one_point_fragments(opts)
    elsif points.negative? then minus_points_fragments(points, opts)
    else
      positive_points_fragments(points)
    end
  end

  def one_point_fragments
    [App.point_singular_prefix, App.point_term]
  end

  def minus_one_point_fragments(opts)
    t = App.jab_term
    [App.jab_singular_prefix, (opts[:bold_jab] ? "*#{t}*" : t)]
  end

  def minus_points_fragments(points, opts)
    t = App.jabs_term
    [formatted_points(points.abs), (opts[:bold_jab] ? "*#{t}*" : t)]
  end

  def positive_points_fragments(points)
    [formatted_points(points), App.points_term]
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
