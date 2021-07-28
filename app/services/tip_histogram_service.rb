# frozen_string_literal: true
class TipHistogramService < Base::Service
  include ChartHelper

  option :profile
  option :user
  option :limit, default: proc {}

  def call
    @limit ||= App.default_tip_history_days

    [points_given, points_received]
  end

  private

  def points_given
    {
      name: "#{App.points_term.titleize} Given",
      data: histogram_data(:tips_sent),
      library: chartjs_library_options(user)
    }
  end

  def points_received
    {
      name: "#{App.points_term.titleize} Received",
      data: histogram_data(:tips_received),
      library: chartjs_library_options(user)
    }
  end

  def histogram_data(assoc)
    data = histogram_records(assoc)
    date_range.each_with_object({}) do |date, hist|
      day = date.strftime('%b %-d')
      hist[day] = data[day] || 0
    end
  end

  def histogram_records(assoc)
    profile
      .send(assoc)
      .where('created_at >= ?', limit.days.ago)
      .group_by_day(:created_at, time_zone: team.time_zone)
      .sum(:quantity)
      .transform_keys { |k| k.strftime('%b %-d') }
  end

  def date_range
    (today - (limit - 1))..today
  end

  def team
    @team ||= profile.team
  end

  def today
    @today ||= Time.use_zone(team.time_zone) { Time.zone.today }
  end
end
